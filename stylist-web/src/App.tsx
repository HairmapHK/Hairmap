import type { Session, User } from '@supabase/supabase-js';
import {
  ArrowLeft,
  BadgeCheck,
  CalendarDays,
  Check,
  Clock3,
  Loader2,
  Lock,
  LogOut,
  MessageCircle,
  Plus,
  RefreshCcw,
  Save,
  Scissors,
  Send,
  Trash2,
  UserRound,
  X,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { FormEvent, useEffect, useMemo, useState } from 'react';
import { supabase } from './supabase';
import type {
  BlockedSlot,
  Booking,
  BookingStatus,
  ChatMessage,
  PortfolioWork,
  Profile,
  ProfileDraft,
  ServiceDraft,
  ServiceItem,
  Stylist,
  StylistApplication,
  WorkDraft,
} from './types';

type TabID = 'bookings' | 'messages' | 'schedule' | 'profile';
type Notice = { type: 'success' | 'error' | 'info'; message: string } | null;

type Thread = {
  id: string;
  customerID: string | null;
  title: string;
  subtitle: string;
  lastText: string;
  lastAt: string;
  booking?: Booking;
  messages: ChatMessage[];
};

const DISTRICTS = [
  '中西區',
  '灣仔區',
  '東區',
  '南區',
  '油尖旺區',
  '深水埗區',
  '九龍城區',
  '黃大仙區',
  '觀塘區',
  '葵青區',
  '荃灣區',
  '屯門區',
  '元朗區',
  '北區',
  '大埔區',
  '沙田區',
  '西貢區',
  '離島區',
];

const DEFAULT_TAGS = ['挑染專家', '經典剪髮', '歐美挑染', '漸層推剪', '韓式燙髮', '縮毛矯正', '女神大波浪', '深層護理'];
const TIME_OPTIONS = Array.from({ length: 22 }, (_, index) => {
  const totalMinutes = 10 * 60 + index * 30;
  const hour = Math.floor(totalMinutes / 60).toString().padStart(2, '0');
  const minute = (totalMinutes % 60).toString().padStart(2, '0');
  return `${hour}:${minute}`;
});

const emptyDraft: ProfileDraft = {
  name: '',
  title: '',
  phone: '',
  district: '油尖旺區',
  location: '',
  basePrice: '380',
  bio: '',
  experience: '5年資歷',
  languages: '中 / 粵 / 英',
  avatarURL: '',
  instagramURL: '',
  tags: ['挑染專家', '經典剪髮'],
  services: [
    { id: 'starter-cut', name: '招牌精修剪髮', category: '剪髮', duration: '60', price: '380', description: '包含溝通、洗髮與造型整理' },
  ],
  works: [],
};

const tabs: Array<{ id: TabID; label: string; icon: LucideIcon }> = [
  { id: 'bookings', label: '預約', icon: CalendarDays },
  { id: 'messages', label: '訊息', icon: MessageCircle },
  { id: 'schedule', label: '檔期', icon: Clock3 },
  { id: 'profile', label: '檔案', icon: UserRound },
];

export default function App() {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [stylists, setStylists] = useState<Stylist[]>([]);
  const [selectedStylistID, setSelectedStylistID] = useState('');
  const [services, setServices] = useState<ServiceItem[]>([]);
  const [works, setWorks] = useState<PortfolioWork[]>([]);
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [blockedSlots, setBlockedSlots] = useState<BlockedSlot[]>([]);
  const [applications, setApplications] = useState<StylistApplication[]>([]);
  const [activeTab, setActiveTab] = useState<TabID>('bookings');
  const [selectedThreadID, setSelectedThreadID] = useState('');
  const [draft, setDraft] = useState<ProfileDraft>(emptyDraft);
  const [selectedDate, setSelectedDate] = useState(todayISO());
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState('');
  const [notice, setNotice] = useState<Notice>(null);

  useEffect(() => {
    let mounted = true;
    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return;
      setSession(data.session);
      setLoading(false);
    });

    const { data: listener } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession);
      if (!nextSession) {
        setProfile(null);
        setStylists([]);
        setBookings([]);
        setMessages([]);
        setBlockedSlots([]);
        setApplications([]);
      }
    });

    return () => {
      mounted = false;
      listener.subscription.unsubscribe();
    };
  }, []);

  useEffect(() => {
    if (!session?.user) return;
    void refreshWorkspace(session.user);
  }, [session?.user?.id]);

  const stylist = useMemo(
    () => stylists.find((item) => item.id === selectedStylistID) ?? stylists[0] ?? null,
    [selectedStylistID, stylists],
  );

  const latestApplication = applications[0] ?? null;

  const threads = useMemo(() => buildThreads(messages, bookings), [messages, bookings]);
  const selectedThread = threads.find((thread) => thread.id === selectedThreadID) ?? threads[0] ?? null;

  const todayBookings = useMemo(
    () => bookings.filter((booking) => booking.booking_date === todayISO() && booking.status !== 'cancelled'),
    [bookings],
  );
  const pendingBookings = useMemo(() => bookings.filter((booking) => booking.status === 'pending'), [bookings]);

  async function refreshWorkspace(user = session?.user) {
    if (!user) return;
    setLoading(true);
    try {
      const { data: profileRow, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();
      if (profileError) throw profileError;

      const resolvedProfile = profileRow as Profile | null;
      setProfile(resolvedProfile);

      const { data: stylistRows, error: stylistError } = await supabase
        .from('stylists')
        .select('*')
        .eq('owner_id', user.id)
        .order('is_active', { ascending: false })
        .order('display_order', { ascending: true });
      if (stylistError) throw stylistError;

      const ownedStylists = ((stylistRows ?? []) as Stylist[]).map(normalizeStylist);
      const preferredStylist =
        ownedStylists.find((item) => item.id === selectedStylistID) ??
        ownedStylists.find((item) => item.is_active) ??
        ownedStylists[0] ??
        null;
      const draftStylistID = preferredStylist?.id ?? resolvedProfile?.stylist_id ?? `pending-stylist-${user.id.slice(0, 8)}`;

      setStylists(ownedStylists);
      setSelectedStylistID(draftStylistID);

      const { data: applicationRows, error: applicationsError } = await supabase
        .from('stylist_applications')
        .select('*')
        .eq('submitted_by', user.id)
        .order('created_at', { ascending: false })
        .limit(20);
      if (applicationsError) throw applicationsError;
      const ownApplications = (applicationRows ?? []) as StylistApplication[];
      setApplications(ownApplications);

      let loadedServices: ServiceItem[] = [];
      let loadedWorks: PortfolioWork[] = [];
      let loadedBookings: Booking[] = [];
      let loadedMessages: ChatMessage[] = [];
      let loadedBlockedSlots: BlockedSlot[] = [];

      if (preferredStylist) {
        const [servicesResult, worksResult, bookingsResult, messagesResult, blockedResult] = await Promise.all([
          supabase
            .from('services')
            .select('*')
            .eq('stylist_id', preferredStylist.id)
            .order('display_order', { ascending: true })
            .order('price', { ascending: true }),
          supabase
            .from('portfolio_works')
            .select('*')
            .eq('stylist_id', preferredStylist.id)
            .order('display_order', { ascending: true })
            .order('created_at', { ascending: false }),
          supabase
            .from('bookings')
            .select('*')
            .or(`stylist_id.eq.${preferredStylist.id},assigned_stylist_id.eq.${preferredStylist.id}`)
            .order('booking_date', { ascending: false })
            .order('start_time', { ascending: false })
            .limit(80),
          supabase
            .from('messages')
            .select('*')
            .eq('stylist_id', preferredStylist.id)
            .order('created_at', { ascending: true })
            .limit(250),
          supabase
            .from('blocked_slots')
            .select('*')
            .eq('stylist_id', preferredStylist.id)
            .gte('work_date', todayISO())
            .order('work_date', { ascending: true })
            .order('start_time', { ascending: true }),
        ]);

        if (servicesResult.error) throw servicesResult.error;
        if (worksResult.error) throw worksResult.error;
        if (bookingsResult.error) throw bookingsResult.error;
        if (messagesResult.error) throw messagesResult.error;
        if (blockedResult.error) throw blockedResult.error;

        loadedServices = (servicesResult.data ?? []) as ServiceItem[];
        loadedWorks = (worksResult.data ?? []) as PortfolioWork[];
        loadedBookings = (bookingsResult.data ?? []) as Booking[];
        loadedMessages = (messagesResult.data ?? []) as ChatMessage[];
        loadedBlockedSlots = (blockedResult.data ?? []) as BlockedSlot[];
      }

      setServices(loadedServices);
      setWorks(loadedWorks);
      setBookings(loadedBookings);
      setMessages(loadedMessages);
      setBlockedSlots(loadedBlockedSlots);
      setDraft(draftFromProfile(preferredStylist, loadedServices, loadedWorks, resolvedProfile, ownApplications[0] ?? null));

      if (!preferredStylist) setActiveTab('profile');
    } catch (error) {
      showError(error);
    } finally {
      setLoading(false);
    }
  }

  async function runAction(label: string, action: () => Promise<void>) {
    setBusy(label);
    setNotice(null);
    try {
      await action();
      await refreshWorkspace();
      setNotice({ type: 'success', message: `${label}完成` });
    } catch (error) {
      showError(error);
    } finally {
      setBusy('');
    }
  }

  function showError(error: unknown) {
    setNotice({ type: 'error', message: error instanceof Error ? error.message : '操作失敗，請稍後再試。' });
  }

  async function updateBookingStatus(booking: Booking, status: BookingStatus) {
    await runAction(statusLabel(status), async () => {
      const { error } = await supabase.from('bookings').update({ status }).eq('id', booking.id);
      if (error) throw error;
    });
  }

  async function sendReply(thread: Thread, text: string) {
    if (!stylist) throw new Error('未找到髮型師檔案。');
    const cleanText = text.trim();
    if (!cleanText) throw new Error('請輸入訊息內容。');

    await runAction('傳送訊息', async () => {
      const now = new Date();
      const { error } = await supabase.from('messages').insert({
        id: `stylist-web-${crypto.randomUUID()}`,
        customer_id: thread.customerID,
        stylist_id: stylist.id,
        sender_role: 'stylist',
        sender_name: stylist.name,
        text: cleanText,
        sent_at: now.toISOString(),
      });
      if (error) throw error;
      setSelectedThreadID(thread.id);
    });
  }

  async function toggleBlockedSlot(time: string) {
    if (!stylist) throw new Error('未找到髮型師檔案。');
    const normalized = normalizeTime(time);
    const existing = blockedSlots.find(
      (slot) => slot.stylist_id === stylist.id && slot.work_date === selectedDate && normalizeTime(slot.start_time) === normalized,
    );

    await runAction(existing ? '解除封鎖檔期' : '封鎖檔期', async () => {
      if (existing) {
        const { error } = await supabase
          .from('blocked_slots')
          .delete()
          .eq('stylist_id', stylist.id)
          .eq('work_date', selectedDate)
          .eq('start_time', normalized);
        if (error) throw error;
      } else {
        const { error } = await supabase.from('blocked_slots').insert({
          id: crypto.randomUUID(),
          stylist_id: stylist.id,
          work_date: selectedDate,
          start_time: normalized,
        });
        if (error) throw error;
      }
    });
  }

  async function submitProfileForReview(event: FormEvent) {
    event.preventDefault();
    if (!session?.user || !profile) throw new Error('請先登入。');

    await runAction('提交檔案審批', async () => {
      const stylistID = stylist?.id ?? profile.stylist_id ?? `pending-stylist-${session.user.id.slice(0, 8)}`;
      const cleanName = draft.name.trim();
      const cleanTitle = draft.title.trim();
      const cleanAvatar = draft.avatarURL.trim();
      const cleanLocation = draft.location.trim();
      const normalizedServices = normalizeServices(stylistID, draft.services);
      const normalizedWorks = normalizeWorks(stylistID, draft.works);

      if (!cleanName) throw new Error('請填寫髮型師姓名。');
      if (!cleanTitle) throw new Error('請填寫頭銜職稱。');
      if (!cleanAvatar) throw new Error('請貼上頭像圖片網址。');
      if (!cleanLocation) throw new Error('請填寫服務地址。');
      if (!normalizedServices.length) throw new Error('至少保留一項服務。');

      const applicationID = `stylist-web-${slugify(cleanName)}-${Date.now()}`;
      const { error } = await supabase.from('stylist_applications').insert({
        id: applicationID,
        submitted_by: session.user.id,
        stylist_id: stylistID,
        owner_id: session.user.id,
        contact_email: profile.email || session.user.email || '',
        salon_id: stylist?.salon_id ?? 'independent-stylist-studio',
        district: draft.district,
        location: cleanLocation,
        name: cleanName,
        title: cleanTitle,
        rating: stylist?.rating ?? 5,
        reviews_count: stylist?.reviews_count ?? 0,
        languages: draft.languages.trim() || '中 / 粵 / 英',
        experience: draft.experience.trim() || '5年資歷',
        specialties: draft.tags,
        avatar_url: cleanAvatar,
        phone: draft.phone.trim(),
        instagram_url: draft.instagramURL.trim(),
        bio: draft.bio.trim(),
        base_price: toInt(draft.basePrice, stylist?.base_price ?? 380),
        services_payload: normalizedServices,
        works_payload: normalizedWorks,
        status: 'pending',
        admin_note: [
          'Android 髮型師手機後台提交',
          stylist ? `更新現有檔案：${stylist.id}` : `建立/補交檔案：${stylistID}`,
          `帳號：${profile.email || session.user.email || '未提供'}`,
          `服務項目：${normalizedServices.length}`,
          `作品：${normalizedWorks.length}`,
        ].join('\n'),
      });
      if (error) throw error;
    });
  }

  if (loading) {
    return <LoadingScreen />;
  }

  if (!session) {
    return <LoginScreen />;
  }

  return (
    <div className="mobile-shell">
      <header className="app-header">
        <div>
          <p className="eyebrow">HAIRMAP STYLIST</p>
          <h1>{stylist?.name || profile?.display_name || '髮型師後台'}</h1>
          <span>{stylist?.title || (latestApplication ? applicationStatusLabel(latestApplication.status) : '手機版工作台')}</span>
        </div>
        <div className="header-actions">
          <IconButton label="刷新" onClick={() => void refreshWorkspace()} disabled={Boolean(busy)} icon={RefreshCcw} />
          <IconButton label="登出" onClick={() => void supabase.auth.signOut()} icon={LogOut} danger />
        </div>
      </header>

      {stylists.length > 1 && (
        <label className="select-card">
          <span>管理檔案</span>
          <select value={selectedStylistID} onChange={(event) => setSelectedStylistID(event.target.value)}>
            {stylists.map((item) => (
              <option key={item.id} value={item.id}>
                {item.name} {item.is_active ? '' : '(已下架)'}
              </option>
            ))}
          </select>
        </label>
      )}

      <section className="summary-grid">
        <Metric title="今日預約" value={todayBookings.length.toString()} icon={CalendarDays} />
        <Metric title="待確認" value={pendingBookings.length.toString()} icon={Clock3} />
        <Metric title="對話" value={threads.length.toString()} icon={MessageCircle} />
        <Metric title="封鎖檔期" value={blockedSlots.length.toString()} icon={Lock} />
      </section>

      {notice && <NoticeBanner notice={notice} onClose={() => setNotice(null)} />}
      {busy && (
        <div className="busy-pill">
          <Loader2 className="spin" size={16} />
          {busy}
        </div>
      )}

      <main className="tab-panel">
        {activeTab === 'bookings' && (
          <BookingsTab
            bookings={bookings}
            hasStylist={Boolean(stylist)}
            openMessages={(booking) => {
              setSelectedThreadID(threadIDForBooking(booking));
              setActiveTab('messages');
            }}
            updateStatus={updateBookingStatus}
          />
        )}
        {activeTab === 'messages' && (
          <MessagesTab
            threads={threads}
            selectedThread={selectedThread}
            setSelectedThreadID={setSelectedThreadID}
            sendReply={sendReply}
          />
        )}
        {activeTab === 'schedule' && (
          <ScheduleTab
            hasStylist={Boolean(stylist)}
            selectedDate={selectedDate}
            setSelectedDate={setSelectedDate}
            blockedSlots={blockedSlots}
            toggleBlockedSlot={toggleBlockedSlot}
          />
        )}
        {activeTab === 'profile' && (
          <ProfileTab
            draft={draft}
            setDraft={setDraft}
            stylist={stylist}
            latestApplication={latestApplication}
            submitProfileForReview={submitProfileForReview}
          />
        )}
      </main>

      <nav className="bottom-nav" aria-label="髮型師後台導覽">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.id}
              className={activeTab === tab.id ? 'active' : ''}
              onClick={() => setActiveTab(tab.id)}
              type="button"
            >
              <Icon size={20} />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </nav>
    </div>
  );
}

function LoadingScreen() {
  return (
    <div className="auth-screen">
      <Loader2 className="spin" />
      <p>連接 Hairmap...</p>
    </div>
  );
}

function LoginScreen() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [message, setMessage] = useState('');
  const [submitting, setSubmitting] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setMessage('');
    const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
    if (error) setMessage(authErrorMessage(error.message));
    setSubmitting(false);
  }

  async function signInWithGoogle() {
    setSubmitting(true);
    setMessage('');
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: authRedirectURL(),
        queryParams: { prompt: 'select_account' },
      },
    });
    if (error) {
      setMessage(authErrorMessage(error.message));
      setSubmitting(false);
    }
  }

  async function resetPassword() {
    if (!email.trim()) {
      setMessage('請先填寫 Email。');
      return;
    }
    setSubmitting(true);
    const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
      redirectTo: authRedirectURL(),
    });
    setMessage(error ? error.message : '已寄出重設密碼 email。');
    setSubmitting(false);
  }

  return (
    <div className="auth-screen">
      <form className="login-card" onSubmit={submit}>
        <div className="brand-mark">H</div>
        <p className="eyebrow">HAIRMAP STYLIST</p>
        <h1>髮型師手機後台</h1>
        <label>
          Email
          <input value={email} onChange={(event) => setEmail(event.target.value)} inputMode="email" placeholder="stylist@example.com" />
        </label>
        <label>
          Password
          <input value={password} onChange={(event) => setPassword(event.target.value)} type="password" placeholder="Password" />
        </label>
        <button className="primary-button" disabled={submitting}>
          {submitting ? <Loader2 className="spin" size={18} /> : <Lock size={18} />}
          登入
        </button>
        <button className="google-button" type="button" onClick={signInWithGoogle} disabled={submitting}>
          <BadgeCheck size={18} />
          使用 Google 登入
        </button>
        <button className="secondary-button" type="button" onClick={resetPassword} disabled={submitting}>
          重設密碼
        </button>
        <a className="apply-link" href={applyURL()}>
          未有髮型師帳號 / 申請加入
        </a>
        {message && <p className="form-message">{message}</p>}
      </form>
    </div>
  );
}

function BookingsTab({
  bookings,
  hasStylist,
  openMessages,
  updateStatus,
}: {
  bookings: Booking[];
  hasStylist: boolean;
  openMessages: (booking: Booking) => void;
  updateStatus: (booking: Booking, status: BookingStatus) => Promise<void>;
}) {
  const upcoming = bookings.filter((booking) => booking.status !== 'cancelled');
  if (!hasStylist) {
    return <EmptyState icon={Scissors} title="先提交髮型師檔案" detail="審批通過後，預約會喺呢度顯示。" />;
  }
  if (!upcoming.length) {
    return <EmptyState icon={CalendarDays} title="未有預約" detail="新預約會自動同步到手機後台。" />;
  }

  return (
    <section className="stack">
      <SectionTitle eyebrow="Bookings" title="預約管理" />
      {upcoming.map((booking) => (
        <article className="booking-card" key={booking.id}>
          <div className="card-topline">
            <span className={`status-badge ${booking.status}`}>{statusLabel(booking.status)}</span>
            <strong>{booking.booking_date}</strong>
          </div>
          <h2>{booking.client_name}</h2>
          <p>{cleanTime(booking.start_time)} - {cleanTime(booking.end_time)} · {booking.service_name}</p>
          <div className="detail-list">
            <span>{booking.client_phone}</span>
            <span>HK$ {booking.price}</span>
            <span>{booking.branch_name || booking.salon_name}</span>
          </div>
          {booking.booking_note && <p className="note">{booking.booking_note}</p>}
          <div className="action-grid">
            <button onClick={() => openMessages(booking)} type="button" className="icon-text">
              <MessageCircle size={17} />
              訊息
            </button>
            {booking.status === 'pending' && (
              <button onClick={() => updateStatus(booking, 'accepted')} type="button" className="success">
                <Check size={17} />
                接受
              </button>
            )}
            {booking.status === 'accepted' && (
              <button onClick={() => updateStatus(booking, 'completed')} type="button" className="success">
                <BadgeCheck size={17} />
                完成
              </button>
            )}
            {booking.status !== 'cancelled' && booking.status !== 'completed' && (
              <button onClick={() => updateStatus(booking, 'cancelled')} type="button" className="danger-soft">
                <X size={17} />
                取消
              </button>
            )}
          </div>
        </article>
      ))}
    </section>
  );
}

function MessagesTab({
  threads,
  selectedThread,
  setSelectedThreadID,
  sendReply,
}: {
  threads: Thread[];
  selectedThread: Thread | null;
  setSelectedThreadID: (id: string) => void;
  sendReply: (thread: Thread, text: string) => Promise<void>;
}) {
  const [reply, setReply] = useState('');

  if (!threads.length) {
    return <EmptyState icon={MessageCircle} title="未有訊息" detail="顧客查詢同預約對話會喺呢度顯示。" />;
  }

  if (selectedThread) {
    return (
      <section className="chat-screen">
        <button className="back-button" type="button" onClick={() => setSelectedThreadID('')}>
          <ArrowLeft size={18} />
          對話列表
        </button>
        <div className="thread-header">
          <strong>{selectedThread.title}</strong>
          <span>{selectedThread.subtitle}</span>
        </div>
        <div className="message-list">
          {selectedThread.messages.length ? (
            selectedThread.messages.map((message) => (
              <div key={message.id} className={`bubble-row ${message.sender_role}`}>
                <div className="bubble">
                  <p>{displayMessageText(message.text)}</p>
                  <span>{displayMessageTime(message)}</span>
                </div>
              </div>
            ))
          ) : (
            <div className="chat-placeholder">未開始對話</div>
          )}
        </div>
        <form
          className="reply-box"
          onSubmit={(event) => {
            event.preventDefault();
            const text = reply;
            setReply('');
            void sendReply(selectedThread, text);
          }}
        >
          <input value={reply} onChange={(event) => setReply(event.target.value)} placeholder="回覆顧客..." />
          <button type="submit">
            <Send size={18} />
          </button>
        </form>
      </section>
    );
  }

  return (
    <section className="stack">
      <SectionTitle eyebrow="Messages" title="顧客訊息" />
      {threads.map((thread) => (
        <button key={thread.id} className="thread-card" onClick={() => setSelectedThreadID(thread.id)} type="button">
          <div className="avatar-dot">{thread.title.slice(0, 1).toUpperCase()}</div>
          <div>
            <strong>{thread.title}</strong>
            <p>{thread.lastText || thread.subtitle}</p>
          </div>
          <span>{thread.lastAt}</span>
        </button>
      ))}
    </section>
  );
}

function ScheduleTab({
  hasStylist,
  selectedDate,
  setSelectedDate,
  blockedSlots,
  toggleBlockedSlot,
}: {
  hasStylist: boolean;
  selectedDate: string;
  setSelectedDate: (date: string) => void;
  blockedSlots: BlockedSlot[];
  toggleBlockedSlot: (time: string) => Promise<void>;
}) {
  if (!hasStylist) {
    return <EmptyState icon={Clock3} title="未有公開檔案" detail="檔案批核後即可管理檔期。" />;
  }
  return (
    <section className="stack">
      <SectionTitle eyebrow="Availability" title="檔期管理" />
      <label className="field-card">
        <span>日期</span>
        <input type="date" value={selectedDate} min={todayISO()} onChange={(event) => setSelectedDate(event.target.value)} />
      </label>
      <div className="time-grid">
        {TIME_OPTIONS.map((time) => {
          const blocked = blockedSlots.some((slot) => slot.work_date === selectedDate && normalizeTime(slot.start_time) === normalizeTime(time));
          return (
            <button key={time} className={blocked ? 'blocked' : ''} type="button" onClick={() => toggleBlockedSlot(time)}>
              <span>{time}</span>
              <small>{blocked ? '已封鎖' : '可預約'}</small>
            </button>
          );
        })}
      </div>
    </section>
  );
}

function ProfileTab({
  draft,
  setDraft,
  stylist,
  latestApplication,
  submitProfileForReview,
}: {
  draft: ProfileDraft;
  setDraft: (draft: ProfileDraft) => void;
  stylist: Stylist | null;
  latestApplication: StylistApplication | null;
  submitProfileForReview: (event: FormEvent) => Promise<void>;
}) {
  return (
    <form className="stack profile-form" onSubmit={(event) => void submitProfileForReview(event)}>
      <SectionTitle eyebrow="Profile" title={stylist ? '更新檔案' : '提交檔案'} />
      {latestApplication && (
        <div className={`application-state ${latestApplication.status}`}>
          <strong>最近提交：{applicationStatusLabel(latestApplication.status)}</strong>
          <span>{formatDateTime(latestApplication.created_at)}</span>
        </div>
      )}

      <div className="form-card">
        <Field label="設計師姓名" value={draft.name} onChange={(value) => setDraft({ ...draft, name: value })} />
        <Field label="頭銜職稱" value={draft.title} onChange={(value) => setDraft({ ...draft, title: value })} />
        <Field label="聯絡電話" value={draft.phone} onChange={(value) => setDraft({ ...draft, phone: value })} inputMode="tel" />
        <div className="field-grid">
          <label>
            主要地區
            <select value={draft.district} onChange={(event) => setDraft({ ...draft, district: event.target.value })}>
              {DISTRICTS.map((district) => (
                <option key={district} value={district}>
                  {district}
                </option>
              ))}
            </select>
          </label>
          <Field label="起價 HK$" value={draft.basePrice} onChange={(value) => setDraft({ ...draft, basePrice: value })} inputMode="numeric" />
        </div>
        <Field label="服務地址" value={draft.location} onChange={(value) => setDraft({ ...draft, location: value })} />
        <TextArea label="個人簡介" value={draft.bio} onChange={(value) => setDraft({ ...draft, bio: value })} />
        <div className="field-grid">
          <Field label="資歷" value={draft.experience} onChange={(value) => setDraft({ ...draft, experience: value })} />
          <Field label="語言" value={draft.languages} onChange={(value) => setDraft({ ...draft, languages: value })} />
        </div>
        <Field label="頭像圖片網址" value={draft.avatarURL} onChange={(value) => setDraft({ ...draft, avatarURL: value })} />
        <Field label="Instagram" value={draft.instagramURL} onChange={(value) => setDraft({ ...draft, instagramURL: value })} />
      </div>

      <div className="form-card">
        <h2>特色標籤</h2>
        <div className="tag-grid">
          {DEFAULT_TAGS.map((tag) => {
            const active = draft.tags.includes(tag);
            return (
              <button
                key={tag}
                type="button"
                className={active ? 'active' : ''}
                onClick={() => {
                  setDraft({
                    ...draft,
                    tags: active ? draft.tags.filter((item) => item !== tag) : [...draft.tags, tag],
                  });
                }}
              >
                {tag}
              </button>
            );
          })}
        </div>
      </div>

      <ServiceEditor draft={draft} setDraft={setDraft} />
      <WorkEditor draft={draft} setDraft={setDraft} />

      <button className="primary-button sticky-submit" type="submit">
        <Save size={18} />
        提交審批
      </button>
    </form>
  );
}

function ServiceEditor({ draft, setDraft }: { draft: ProfileDraft; setDraft: (draft: ProfileDraft) => void }) {
  function updateService(id: string, patch: Partial<ServiceDraft>) {
    setDraft({
      ...draft,
      services: draft.services.map((service) => (service.id === id ? { ...service, ...patch } : service)),
    });
  }

  return (
    <div className="form-card">
      <div className="card-heading">
        <h2>服務項目</h2>
        <button
          type="button"
          className="mini-button"
          onClick={() =>
            setDraft({
              ...draft,
              services: [
                ...draft.services,
                { id: `service-${crypto.randomUUID()}`, name: '', category: '剪髮', duration: '60', price: '', description: '' },
              ],
            })
          }
        >
          <Plus size={16} />
          新增
        </button>
      </div>
      {draft.services.map((service, index) => (
        <div className="service-card" key={service.id}>
          <div className="service-title">
            <strong>服務 {index + 1}</strong>
            {draft.services.length > 1 && (
              <button
                type="button"
                onClick={() => setDraft({ ...draft, services: draft.services.filter((item) => item.id !== service.id) })}
                aria-label="刪除服務"
              >
                <Trash2 size={17} />
              </button>
            )}
          </div>
          <Field label="服務名稱" value={service.name} onChange={(value) => updateService(service.id, { name: value })} />
          <Field label="類別" value={service.category} onChange={(value) => updateService(service.id, { category: value })} />
          <div className="field-grid">
            <Field label="需時分鐘" value={service.duration} onChange={(value) => updateService(service.id, { duration: value })} inputMode="numeric" />
            <Field label="價錢 HK$" value={service.price} onChange={(value) => updateService(service.id, { price: value })} inputMode="numeric" />
          </div>
          <Field label="簡短描述" value={service.description} onChange={(value) => updateService(service.id, { description: value })} />
        </div>
      ))}
    </div>
  );
}

function WorkEditor({ draft, setDraft }: { draft: ProfileDraft; setDraft: (draft: ProfileDraft) => void }) {
  function updateWork(id: string, patch: Partial<WorkDraft>) {
    setDraft({
      ...draft,
      works: draft.works.map((work) => (work.id === id ? { ...work, ...patch } : work)),
    });
  }

  return (
    <div className="form-card">
      <div className="card-heading">
        <h2>作品</h2>
        <button
          type="button"
          className="mini-button"
          onClick={() =>
            setDraft({
              ...draft,
              works: [...draft.works, { id: `work-${crypto.randomUUID()}`, title: '', imageURL: '', mediaKind: 'photo', videoURL: '', thumbnailURL: '' }],
            })
          }
        >
          <Plus size={16} />
          新增
        </button>
      </div>
      {draft.works.length === 0 && <p className="muted-text">可先留空，之後再補作品。</p>}
      {draft.works.map((work) => (
        <div className="work-card" key={work.id}>
          {work.imageURL && <img src={work.imageURL} alt={work.title || '作品'} />}
          <Field label="作品標題" value={work.title} onChange={(value) => updateWork(work.id, { title: value })} />
          <Field label="圖片網址" value={work.imageURL} onChange={(value) => updateWork(work.id, { imageURL: value })} />
          <button type="button" className="danger-soft" onClick={() => setDraft({ ...draft, works: draft.works.filter((item) => item.id !== work.id) })}>
            <Trash2 size={17} />
            刪除作品
          </button>
        </div>
      ))}
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  inputMode,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  inputMode?: 'text' | 'numeric' | 'tel' | 'email' | 'url';
}) {
  return (
    <label>
      {label}
      <input value={value} onChange={(event) => onChange(event.target.value)} inputMode={inputMode} />
    </label>
  );
}

function TextArea({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label>
      {label}
      <textarea value={value} onChange={(event) => onChange(event.target.value)} rows={4} />
    </label>
  );
}

function Metric({ title, value, icon: Icon }: { title: string; value: string; icon: LucideIcon }) {
  return (
    <div className="metric">
      <Icon size={18} />
      <span>{title}</span>
      <strong>{value}</strong>
    </div>
  );
}

function SectionTitle({ eyebrow, title }: { eyebrow: string; title: string }) {
  return (
    <div className="section-title">
      <p className="eyebrow">{eyebrow}</p>
      <h2>{title}</h2>
    </div>
  );
}

function EmptyState({ icon: Icon, title, detail }: { icon: LucideIcon; title: string; detail: string }) {
  return (
    <div className="empty-state">
      <Icon size={34} />
      <h2>{title}</h2>
      <p>{detail}</p>
    </div>
  );
}

function IconButton({
  label,
  onClick,
  icon: Icon,
  disabled,
  danger,
}: {
  label: string;
  onClick: () => void;
  icon: LucideIcon;
  disabled?: boolean;
  danger?: boolean;
}) {
  return (
    <button className={`icon-button ${danger ? 'danger' : ''}`} onClick={onClick} disabled={disabled} aria-label={label} title={label} type="button">
      <Icon size={19} />
    </button>
  );
}

function NoticeBanner({ notice, onClose }: { notice: Exclude<Notice, null>; onClose: () => void }) {
  return (
    <div className={`notice ${notice.type}`}>
      <span>{notice.message}</span>
      <button type="button" onClick={onClose} aria-label="關閉">
        <X size={16} />
      </button>
    </div>
  );
}

function buildThreads(messages: ChatMessage[], bookings: Booking[]): Thread[] {
  const grouped = new Map<string, ChatMessage[]>();
  for (const message of messages) {
    const key = message.customer_id ? `customer-${message.customer_id}` : `guest-${message.stylist_id}`;
    grouped.set(key, [...(grouped.get(key) ?? []), message]);
  }

  const bookingByThread = new Map<string, Booking>();
  for (const booking of bookings) {
    const key = threadIDForBooking(booking);
    const current = bookingByThread.get(key);
    if (!current || bookingSortValue(booking) > bookingSortValue(current)) {
      bookingByThread.set(key, booking);
    }
  }

  const threadIDs = new Set([...grouped.keys(), ...bookingByThread.keys()]);
  return Array.from(threadIDs)
    .map((id) => {
      const threadMessages = (grouped.get(id) ?? []).sort((lhs, rhs) => messageSortValue(lhs) - messageSortValue(rhs));
      const booking = bookingByThread.get(id);
      const latestMessage = threadMessages[threadMessages.length - 1];
      const customerID = latestMessage?.customer_id ?? booking?.customer_id ?? null;
      const title = booking?.client_name || latestMessage?.sender_name || '顧客';
      const subtitle = booking ? `${booking.booking_date} ${cleanTime(booking.start_time)} · ${booking.service_name}` : '顧客查詢';
      return {
        id,
        customerID,
        title,
        subtitle,
        lastText: latestMessage ? displayMessageText(latestMessage.text) : subtitle,
        lastAt: latestMessage ? displayMessageTime(latestMessage) : booking ? cleanTime(booking.start_time) : '',
        booking,
        messages: threadMessages,
      };
    })
    .sort((lhs, rhs) => {
      const lhsLast = lhs.messages[lhs.messages.length - 1];
      const rhsLast = rhs.messages[rhs.messages.length - 1];
      const lhsValue = lhsLast ? messageSortValue(lhsLast) : lhs.booking ? bookingSortValue(lhs.booking) : 0;
      const rhsValue = rhsLast ? messageSortValue(rhsLast) : rhs.booking ? bookingSortValue(rhs.booking) : 0;
      return rhsValue - lhsValue;
    });
}

function threadIDForBooking(booking: Booking) {
  return booking.customer_id ? `customer-${booking.customer_id}` : `booking-${booking.id}`;
}

function draftFromProfile(
  stylist: Stylist | null,
  services: ServiceItem[],
  works: PortfolioWork[],
  profile: Profile | null,
  latestApplication: StylistApplication | null,
): ProfileDraft {
  if (!stylist && latestApplication) {
    return {
      name: latestApplication.name,
      title: latestApplication.title,
      phone: latestApplication.phone || '',
      district: latestApplication.district || '油尖旺區',
      location: latestApplication.location,
      basePrice: String(latestApplication.base_price || 380),
      bio: latestApplication.bio,
      experience: latestApplication.experience,
      languages: latestApplication.languages,
      avatarURL: latestApplication.avatar_url,
      instagramURL: latestApplication.instagram_url,
      tags: latestApplication.specialties?.length ? latestApplication.specialties : emptyDraft.tags,
      services: serviceDrafts(latestApplication.services_payload, latestApplication.stylist_id),
      works: workDrafts(latestApplication.works_payload),
    };
  }

  if (!stylist) {
    return {
      ...emptyDraft,
      name: profile?.display_name?.trim() || '',
      avatarURL: profile?.avatar_url || '',
    };
  }

  return {
    name: stylist.name,
    title: stylist.title,
    phone: stylist.phone || '',
    district: stylist.district || '油尖旺區',
    location: stylist.location || '',
    basePrice: String(stylist.base_price || 380),
    bio: stylist.bio || '',
    experience: stylist.experience || '5年資歷',
    languages: stylist.languages || '中 / 粵 / 英',
    avatarURL: stylist.avatar_url || '',
    instagramURL: stylist.instagram_url || '',
    tags: stylist.specialties?.length ? stylist.specialties : emptyDraft.tags,
    services: serviceDrafts(services, stylist.id),
    works: workDrafts(works),
  };
}

function serviceDrafts(services: ServiceItem[], stylistID: string): ServiceDraft[] {
  const mapped = (services ?? []).map((service) => ({
    id: service.id || `service-${crypto.randomUUID()}`,
    name: service.name || '',
    category: service.category || '剪髮',
    duration: String(service.duration || 60),
    price: String(service.price || ''),
    description: service.description || '',
  }));
  if (mapped.length) return mapped;
  return emptyDraft.services.map((service) => ({ ...service, id: `${stylistID}-${service.id}` }));
}

function workDrafts(works: PortfolioWork[]): WorkDraft[] {
  return (works ?? []).map((work) => ({
    id: work.id || `work-${crypto.randomUUID()}`,
    title: work.title || '',
    imageURL: work.image_url || '',
    mediaKind: work.media_kind || 'photo',
    videoURL: work.video_url || '',
    thumbnailURL: work.thumbnail_url || '',
  }));
}

function normalizeServices(stylistID: string, services: ServiceDraft[]): ServiceItem[] {
  return services
    .map((service, index) => ({
      id: service.id.startsWith(stylistID) ? service.id : `${stylistID}_service_${index + 1}_${slugify(service.name || 'item')}`,
      stylist_id: stylistID,
      name: service.name.trim(),
      category: service.category.trim() || '剪髮',
      duration: toInt(service.duration, 60),
      description: service.description.trim(),
      price: toInt(service.price, 0),
      is_active: true,
      display_order: (index + 1) * 10,
    }))
    .filter((service) => service.name && service.price > 0);
}

function normalizeWorks(stylistID: string, works: WorkDraft[]): PortfolioWork[] {
  return works
    .map((work, index) => ({
      id: work.id.startsWith(stylistID) ? work.id : `${stylistID}_work_${index + 1}_${slugify(work.title || 'look')}`,
      stylist_id: stylistID,
      title: work.title.trim() || `作品 ${index + 1}`,
      image_url: work.imageURL.trim(),
      media_kind: work.mediaKind,
      video_url: work.videoURL.trim(),
      thumbnail_url: work.thumbnailURL.trim() || work.imageURL.trim(),
      is_active: true,
      display_order: (index + 1) * 10,
    }))
    .filter((work) => work.image_url);
}

function normalizeStylist(stylist: Stylist): Stylist {
  return {
    ...stylist,
    specialties: Array.isArray(stylist.specialties) ? stylist.specialties : [],
    district: stylist.district || '',
    location: stylist.location || '',
    phone: stylist.phone || '',
    instagram_url: stylist.instagram_url || '',
    bio: stylist.bio || '',
    base_price: stylist.base_price || 0,
    is_active: stylist.is_active ?? true,
    is_featured: stylist.is_featured ?? false,
    display_order: stylist.display_order ?? 100,
  };
}

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

function normalizeTime(time: string) {
  const [hour = '00', minute = '00'] = time.split(':');
  return `${hour.padStart(2, '0')}:${minute.padStart(2, '0')}:00`;
}

function cleanTime(time: string) {
  return time.slice(0, 5);
}

function statusLabel(status: BookingStatus) {
  switch (status) {
    case 'pending':
      return '待確認';
    case 'accepted':
      return '已接受';
    case 'in_progress':
      return '進行中';
    case 'completed':
      return '已完成';
    case 'cancelled':
      return '已取消';
  }
}

function applicationStatusLabel(status: string) {
  switch (status) {
    case 'pending':
      return '待審批';
    case 'approved':
      return '已批准';
    case 'rejected':
      return '已拒絕';
    case 'hidden':
      return '已下架';
    default:
      return status;
  }
}

function displayMessageText(text: string) {
  const prefix = 'hairmap-photo::';
  return text.startsWith(prefix) ? '已分享髮型參考照片' : text;
}

function displayMessageTime(message: ChatMessage) {
  const raw = message.created_at || message.sent_at;
  const date = new Date(raw);
  if (Number.isNaN(date.getTime())) return raw.slice(0, 5);
  return date.toLocaleTimeString('zh-HK', { hour: '2-digit', minute: '2-digit' });
}

function formatDateTime(raw: string) {
  const date = new Date(raw);
  if (Number.isNaN(date.getTime())) return raw;
  return date.toLocaleString('zh-HK', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function messageSortValue(message: ChatMessage) {
  const date = new Date(message.created_at || message.sent_at);
  return Number.isNaN(date.getTime()) ? 0 : date.getTime();
}

function bookingSortValue(booking: Booking) {
  const date = new Date(`${booking.booking_date}T${cleanTime(booking.start_time)}:00`);
  return Number.isNaN(date.getTime()) ? 0 : date.getTime();
}

function toInt(value: string | number, fallback: number) {
  if (typeof value === 'number') return Number.isFinite(value) ? value : fallback;
  const number = Number.parseInt(value.replace(/[^\d]/g, ''), 10);
  return Number.isFinite(number) ? number : fallback;
}

function slugify(value: string) {
  const slug = value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\u4e00-\u9fa5]+/g, '-')
    .replace(/^-+|-+$/g, '');
  return slug || 'stylist';
}

function applyURL() {
  if (window.location.pathname.includes('/Hairmap/stylist')) return '/Hairmap/apply/';
  return '/apply/';
}

function authRedirectURL() {
  const url = new URL(window.location.href);
  url.search = '';
  url.hash = '';
  if (url.pathname.includes('/Hairmap/stylist')) {
    url.pathname = '/Hairmap/stylist/';
  }
  return url.toString();
}

function authErrorMessage(message: string) {
  if (message.toLowerCase().includes('invalid login credentials')) {
    return 'Email / 密碼不正確。如果你平時用 Google 登入，請按「使用 Google 登入」。';
  }
  return message;
}
