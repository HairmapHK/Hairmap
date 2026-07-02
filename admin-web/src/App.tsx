import { Session, User } from '@supabase/supabase-js';
import {
  AlertTriangle,
  ArrowDown,
  ArrowUp,
  BadgeCheck,
  BarChart3,
  Check,
  ChevronRight,
  Eye,
  EyeOff,
  ExternalLink,
  Film,
  Flag,
  Home,
  Image,
  LayoutDashboard,
  ListChecks,
  Loader2,
  LogOut,
  RefreshCcw,
  Scissors,
  Search,
  Shield,
  Sparkles,
  Star,
  Store,
  X,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { FormEvent, useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { supabase } from './supabase';
import type {
  AdminData,
  AdminUser,
  ApplicationStatus,
  DetailTarget,
  HomepageItem,
  HomepageSection,
  InspirationComment,
  InspirationItem,
  PortfolioWork,
  RankingOverride,
  Report,
  ReportStatus,
  Salon,
  SalonApplication,
  SalonBrand,
  SalonServiceItem,
  SalonWork,
  ServiceItem,
  Stylist,
  StylistApplication,
} from './types';

const emptyData: AdminData = {
  profiles: [],
  stylists: [],
  salons: [],
  services: [],
  salonBrands: [],
  salonServices: [],
  works: [],
  salonWorks: [],
  stylistApplications: [],
  salonApplications: [],
  inspirations: [],
  comments: [],
  reports: [],
  homepageSections: [],
  homepageItems: [],
  rankingOverrides: [],
};

const tabs = [
  { id: 'dashboard', label: '總覽', icon: LayoutDashboard },
  { id: 'applications', label: '審批', icon: ListChecks },
  { id: 'catalog', label: '檔案', icon: Scissors },
  { id: 'content', label: '靈感/檢舉', icon: Flag },
  { id: 'placement', label: '首頁/排行', icon: BarChart3 },
] as const;

type TabID = (typeof tabs)[number]['id'];
type CatalogVisibilityFilter = 'active' | 'hidden' | 'featured' | 'all';
type CatalogEntityType = 'stylist' | 'salon';
type ContentVisibilityFilter = 'active' | 'hidden' | 'featured' | 'broken' | 'all';
type PlacementItemType = HomepageItem['item_type'];
type RankingItemType = RankingOverride['item_type'];

type Toast = {
  type: 'success' | 'error' | 'info';
  message: string;
};

type DetailField = {
  label: string;
  value: ReactNode;
};

type DetailSection = {
  title: string;
  fields: DetailField[];
};

type DetailMediaItem = {
  title: string;
  imageURL: string;
  mediaKind: 'photo' | 'video';
  videoURL?: string;
};

type DetailMediaCounts = {
  total: number;
  videos: number;
};

export default function App() {
  const [session, setSession] = useState<Session | null>(null);
  const [admin, setAdmin] = useState<AdminUser | null>(null);
  const [data, setData] = useState<AdminData>(emptyData);
  const [activeTab, setActiveTab] = useState<TabID>('dashboard');
  const [statusFilter, setStatusFilter] = useState<ApplicationStatus | 'all'>('pending');
  const [query, setQuery] = useState('');
  const [detail, setDetail] = useState<DetailTarget | null>(null);
  const [loading, setLoading] = useState(true);
  const [busyLabel, setBusyLabel] = useState('');
  const [toast, setToast] = useState<Toast | null>(null);

  useEffect(() => {
    let mounted = true;
    supabase.auth.getSession().then(({ data: authData }) => {
      if (!mounted) return;
      setSession(authData.session);
      setLoading(false);
    });

    const { data: listener } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession);
      if (!nextSession) {
        setAdmin(null);
        setData(emptyData);
      }
    });

    return () => {
      mounted = false;
      listener.subscription.unsubscribe();
    };
  }, []);

  useEffect(() => {
    if (!session?.user) return;
    void bootstrap(session.user);
  }, [session?.user?.id]);

  async function bootstrap(user: User) {
    setLoading(true);
    try {
      const { data: adminRow, error } = await supabase
        .from('admin_users')
        .select('*')
        .eq('user_id', user.id)
        .maybeSingle();

      if (error) throw error;
      if (!adminRow) {
        setAdmin(null);
        setData(emptyData);
        setToast({ type: 'error', message: '此帳號未加入 admin_users，無法進入後台。' });
        return;
      }

      setAdmin(adminRow as AdminUser);
      await refreshData();
    } catch (error) {
      showError(error);
    } finally {
      setLoading(false);
    }
  }

  async function refreshData() {
    const [
      profiles,
      stylists,
      salons,
      services,
      salonBrands,
      salonServices,
      works,
      salonWorks,
      stylistApplications,
      salonApplications,
      inspirations,
      comments,
      reports,
      homepageSections,
      homepageItems,
      rankingOverrides,
    ] = await Promise.all([
      selectAll('profiles', 'updated_at', false),
      selectAll('stylists', 'display_order', true),
      selectAll('salons', 'display_order', true),
      selectAll('services', 'display_order', true),
      selectAll('salon_brands', 'display_order', true),
      selectAll('salon_services', 'display_order', true),
      selectAll('portfolio_works', 'display_order', true),
      selectAll('salon_portfolio_works', 'display_order', true),
      selectAll('stylist_applications', 'created_at', false),
      selectAll('salon_applications', 'created_at', false),
      selectInspirations(),
      selectAll('inspiration_comments', 'created_at', false),
      selectAll('reports', 'created_at', false),
      selectAll('homepage_sections', 'sort_order', true),
      selectAll('homepage_items', 'sort_order', true),
      selectAll('ranking_overrides', 'manual_rank', true),
    ]);

    setData({
      profiles: profiles as AdminData['profiles'],
      stylists: stylists as Stylist[],
      salons: salons as Salon[],
      services: services as ServiceItem[],
      salonBrands: salonBrands as SalonBrand[],
      salonServices: salonServices as SalonServiceItem[],
      works: works as PortfolioWork[],
      salonWorks: salonWorks as SalonWork[],
      stylistApplications: stylistApplications as StylistApplication[],
      salonApplications: salonApplications as SalonApplication[],
      inspirations: inspirations as InspirationItem[],
      comments: comments as InspirationComment[],
      reports: reports as Report[],
      homepageSections: homepageSections as HomepageSection[],
      homepageItems: homepageItems as HomepageItem[],
      rankingOverrides: rankingOverrides as RankingOverride[],
    });
  }

  async function selectAll(table: string, orderColumn: string, ascending: boolean) {
    const { data, error } = await supabase
      .from(table)
      .select('*')
      .order(orderColumn, { ascending, nullsFirst: false });
    if (error) throw error;
    return data ?? [];
  }

  async function selectInspirations() {
    const { data, error } = await supabase
      .from('inspiration_items')
      .select('*')
      .order('display_order', { ascending: true, nullsFirst: false })
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data ?? [];
  }

  async function runAction(label: string, action: () => Promise<void>) {
    setBusyLabel(label);
    try {
      await action();
      await refreshData();
      setToast({ type: 'success', message: `${label}完成` });
    } catch (error) {
      showError(error);
    } finally {
      setBusyLabel('');
    }
  }

  function showError(error: unknown) {
    setToast({ type: 'error', message: describeError(error) });
  }

  const counts = useMemo(() => {
    const latestStylistApplications = latestApplications(data.stylistApplications, (item) => item.stylist_id);
    const latestSalonApplications = latestApplications(data.salonApplications, (item) => item.salon_id);
    const pendingStylists = latestStylistApplications.filter((item) => item.status === 'pending').length;
    const pendingSalons = latestSalonApplications.filter((item) => item.status === 'pending').length;
    const openReports = data.reports.filter((item) => item.status === 'open' || item.status === 'reviewing').length;
    const hiddenComments = data.comments.filter((item) => item.is_hidden).length;
    return { pendingStylists, pendingSalons, openReports, hiddenComments };
  }, [data]);

  if (loading) {
    return (
      <ShellFrame>
        <div className="center-state">
          <Loader2 className="spin" />
          <p>正在連接 Hairmap Admin...</p>
        </div>
      </ShellFrame>
    );
  }

  if (!session) {
    return <LoginScreen />;
  }

  if (!admin) {
    return (
      <ShellFrame>
        <div className="auth-card">
          <Shield size={38} />
          <h1>未授權</h1>
          <p>你已登入，但此帳號未在 Supabase `admin_users` 內。請用 super_admin 帳號登入。</p>
          <button className="primary" onClick={() => supabase.auth.signOut()}>
            登出
          </button>
        </div>
      </ShellFrame>
    );
  }

  return (
    <ShellFrame>
      <header className="topbar">
        <div>
          <p className="eyebrow">HAIRMAP OPERATIONS</p>
          <h1>Admin 後台</h1>
        </div>
        <div className="topbar-actions">
          <div className="admin-chip">
            <Shield size={16} />
            <span>{admin.display_name || session.user.email}</span>
            <strong>{admin.role}</strong>
          </div>
          <button className="ghost" onClick={() => runAction('刷新資料', refreshData)} disabled={Boolean(busyLabel)}>
            <RefreshCcw size={16} />
            刷新
          </button>
          <button className="danger-soft" onClick={() => supabase.auth.signOut()}>
            <LogOut size={16} />
            登出
          </button>
        </div>
      </header>

      <main className="layout">
        <aside className="sidebar">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                className={`nav-item ${activeTab === tab.id ? 'active' : ''}`}
                onClick={() => setActiveTab(tab.id)}
              >
                <Icon size={18} />
                {tab.label}
              </button>
            );
          })}
        </aside>

        <section className="workspace">
          <Toolbar query={query} setQuery={setQuery} busyLabel={busyLabel} />
          {activeTab === 'dashboard' && <Dashboard counts={counts} data={data} setTab={setActiveTab} setDetail={setDetail} />}
          {activeTab === 'applications' && (
            <Applications
              data={data}
              query={query}
              statusFilter={statusFilter}
              setStatusFilter={setStatusFilter}
              setDetail={setDetail}
              approveStylist={(app) => runAction('批准髮型師申請', () => approveStylistApplication(app, session.user.id, data))}
              rejectStylist={(app) => runAction('拒絕髮型師申請', () => updateStylistApplicationStatus(app, 'rejected', session.user.id))}
              hideStylist={(app) => runAction('下架髮型師檔案', () => hideStylistApplication(app, session.user.id))}
              approveSalon={(app) => runAction('批准沙龍申請', () => approveSalonApplication(app, session.user.id, data))}
              rejectSalon={(app) => runAction('拒絕沙龍申請', () => updateSalonApplicationStatus(app, 'rejected', session.user.id))}
              hideSalon={(app) => runAction('下架沙龍檔案', () => hideSalonApplication(app, session.user.id))}
            />
          )}
          {activeTab === 'catalog' && (
            <Catalog
              data={data}
              query={query}
              setDetail={setDetail}
              updateStylist={(id, payload) => runAction('更新髮型師狀態', () => updateTable('stylists', id, payload))}
              updateSalon={(id, payload) => runAction('更新沙龍狀態', () => updateTable('salons', id, payload))}
              setStylistVisibility={(id, active) => runAction(active ? '上架髮型師檔案' : '下架髮型師檔案', () => setCatalogVisibility('stylist', id, active, session.user.id))}
              setSalonVisibility={(id, active) => runAction(active ? '上架沙龍檔案' : '下架沙龍檔案', () => setCatalogVisibility('salon', id, active, session.user.id))}
              setRanking={(type, id, rank) => runAction('更新排行榜', () => upsertRanking(type, id, rank, data))}
              repairExposure={() => runAction('修復下架曝光', () => repairHiddenExposure(data))}
            />
          )}
          {activeTab === 'content' && (
            <ContentModeration
              data={data}
              query={query}
              setDetail={setDetail}
              updateInspiration={(id, payload) => runAction('更新靈感內容', () => updateTable('inspiration_items', id, payload))}
              deleteInspiration={(item) => runAction('刪除靈感內容', () => deleteInspiration(item))}
              repairBrokenInspirations={() => runAction('隱藏壞圖靈感內容', () => repairBrokenInspirations(data))}
              toggleComment={(comment) => runAction('更新留言狀態', () => updateTable('inspiration_comments', comment.id, { is_hidden: !comment.is_hidden }))}
              updateReport={(report, status) => runAction('更新檢舉狀態', () => updateReportStatus(report, status, session.user.id))}
            />
          )}
          {activeTab === 'placement' && (
            <Placement
              data={data}
              query={query}
              addHomepageItem={(item) => runAction('加入首頁推薦', () => upsertHomepageItem(item, data))}
              updateHomepageItem={(id, payload) => runAction('更新首頁項目', () => updateHomepageItemRecord(data, id, payload))}
              setRanking={(type, id, rank) => runAction('更新排行榜', () => upsertRanking(type, id, rank, data))}
            />
          )}
        </section>
      </main>

      {toast && <ToastView toast={toast} onClose={() => setToast(null)} />}
      {detail && (
        <DetailDrawer
          detail={detail}
          data={data}
          onClose={() => setDetail(null)}
          approveStylist={(app) => runAction('批准髮型師申請', () => approveStylistApplication(app, session.user.id, data))}
          rejectStylist={(app) => runAction('拒絕髮型師申請', () => updateStylistApplicationStatus(app, 'rejected', session.user.id))}
          hideStylist={(app) => runAction('下架髮型師檔案', () => hideStylistApplication(app, session.user.id))}
          approveSalon={(app) => runAction('批准沙龍申請', () => approveSalonApplication(app, session.user.id, data))}
          rejectSalon={(app) => runAction('拒絕沙龍申請', () => updateSalonApplicationStatus(app, 'rejected', session.user.id))}
          hideSalon={(app) => runAction('下架沙龍檔案', () => hideSalonApplication(app, session.user.id))}
        />
      )}
    </ShellFrame>
  );
}

function ShellFrame({ children }: { children: ReactNode }) {
  return <div className="admin-shell">{children}</div>;
}

function LoginScreen() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState('');

  async function submit(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setMessage('');
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) setMessage(error.message);
    setSubmitting(false);
  }

  async function signInWithGoogle() {
    await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: window.location.origin },
    });
  }

  return (
    <ShellFrame>
      <div className="auth-card">
        <div className="brand-mark">H</div>
        <p className="eyebrow">HAIRMAP ADMIN</p>
        <h1>營運後台登入</h1>
        <p>只限已加入 Supabase `admin_users` 的管理員帳號。</p>
        <form onSubmit={submit} className="login-form">
          <label>
            Email
            <input value={email} onChange={(event) => setEmail(event.target.value)} placeholder="admin@example.com" />
          </label>
          <label>
            Password
            <input type="password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Password" />
          </label>
          <button className="primary" disabled={submitting}>
            {submitting ? <Loader2 className="spin" size={16} /> : <Shield size={16} />}
            使用 Email 登入
          </button>
        </form>
        <button className="ghost wide" onClick={signInWithGoogle}>
          使用 Google 登入
        </button>
        {message && <p className="error-text">{message}</p>}
      </div>
    </ShellFrame>
  );
}

function Toolbar({
  query,
  setQuery,
  busyLabel,
}: {
  query: string;
  setQuery: (query: string) => void;
  busyLabel: string;
}) {
  return (
    <div className="toolbar">
      <div className="searchbox">
        <Search size={17} />
        <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="搜尋名稱、地區、ID、電話、狀態..." />
      </div>
      {busyLabel && (
        <div className="busy">
          <Loader2 size={16} className="spin" />
          {busyLabel}
        </div>
      )}
    </div>
  );
}

function Dashboard({
  counts,
  data,
  setTab,
  setDetail,
}: {
  counts: { pendingStylists: number; pendingSalons: number; openReports: number; hiddenComments: number };
  data: AdminData;
  setTab: (tab: TabID) => void;
  setDetail: (detail: DetailTarget) => void;
}) {
  const recentStylist = data.stylistApplications[0];
  const recentSalon = data.salonApplications[0];
  const recentReport = data.reports[0];

  return (
    <div className="stack">
      <div className="metric-grid">
        <Metric title="待審批髮型師" value={counts.pendingStylists} icon={Scissors} onClick={() => setTab('applications')} />
        <Metric title="待審批沙龍" value={counts.pendingSalons} icon={Store} onClick={() => setTab('applications')} />
        <Metric title="未完成檢舉" value={counts.openReports} icon={Flag} onClick={() => setTab('content')} />
        <Metric title="已隱藏留言" value={counts.hiddenComments} icon={EyeOff} onClick={() => setTab('content')} />
      </div>

      <div className="section-head">
        <div>
          <p className="eyebrow">LIVE OPS</p>
          <h2>營運快照</h2>
        </div>
      </div>

      <div className="two-col">
        <div className="panel">
          <h3>最新申請</h3>
          {recentStylist && <MiniRow title={recentStylist.name} meta={`髮型師 · ${recentStylist.status}`} onClick={() => setDetail({ kind: 'stylistApplication', item: recentStylist })} />}
          {recentSalon && <MiniRow title={recentSalon.name} meta={`沙龍 · ${recentSalon.status}`} onClick={() => setDetail({ kind: 'salonApplication', item: recentSalon })} />}
          {!recentStylist && !recentSalon && <EmptyLine text="暫時沒有申請。" />}
        </div>
        <div className="panel">
          <h3>最新檢舉</h3>
          {recentReport ? (
            <MiniRow title={`${recentReport.entity_type} · ${recentReport.reason}`} meta={recentReport.status} onClick={() => setDetail({ kind: 'report', item: recentReport })} />
          ) : (
            <EmptyLine text="暫時沒有檢舉。" />
          )}
        </div>
      </div>
    </div>
  );
}

function Applications({
  data,
  query,
  statusFilter,
  setStatusFilter,
  setDetail,
  approveStylist,
  rejectStylist,
  hideStylist,
  approveSalon,
  rejectSalon,
  hideSalon,
}: {
  data: AdminData;
  query: string;
  statusFilter: ApplicationStatus | 'all';
  setStatusFilter: (status: ApplicationStatus | 'all') => void;
  setDetail: (detail: DetailTarget) => void;
  approveStylist: (item: StylistApplication) => void;
  rejectStylist: (item: StylistApplication) => void;
  hideStylist: (item: StylistApplication) => void;
  approveSalon: (item: SalonApplication) => void;
  rejectSalon: (item: SalonApplication) => void;
  hideSalon: (item: SalonApplication) => void;
}) {
  const stylistApplications = useMemo(
    () => filterApplications(latestApplications(data.stylistApplications, (item) => item.stylist_id), query, statusFilter),
    [data.stylistApplications, query, statusFilter],
  );
  const salonApplications = useMemo(
    () => filterApplications(latestApplications(data.salonApplications, (item) => item.salon_id), query, statusFilter),
    [data.salonApplications, query, statusFilter],
  );

  return (
    <div className="stack">
      <div className="section-head">
        <div>
          <p className="eyebrow">APPROVAL QUEUE</p>
          <h2>髮型師 / 沙龍審批</h2>
        </div>
        <Segmented
          value={statusFilter}
          onChange={(value) => setStatusFilter(value as ApplicationStatus | 'all')}
          options={[
            ['pending', '待審批'],
            ['approved', '已批准'],
            ['rejected', '已拒絕'],
            ['hidden', '已下架'],
            ['all', '全部'],
          ]}
        />
      </div>

      <div className="two-col">
        <div className="panel">
          <PanelTitle icon={Scissors} title="髮型師申請" count={stylistApplications.length} />
          <div className="record-list">
            {stylistApplications.map((item) => (
              <ApplicationCard
                key={item.id}
                image={item.avatar_url}
                title={item.name}
                subtitle={`${item.title} · ${item.contact_email || item.phone || '未填聯絡'}`}
                status={item.status}
                chips={[
                  item.claimed_by ? '已連接 App 帳號' : item.status === 'approved' ? '待同 email 註冊自動連接' : '待批准後可自動連接',
                  item.instagram_url ? 'IG 已提供' : '',
                  item.experience,
                  item.languages,
                  ...item.specialties.slice(0, 3),
                ]}
                onView={() => setDetail({ kind: 'stylistApplication', item })}
                actions={
                  <>
                    {item.status === 'pending' && <ActionButton icon={Check} label="批准" tone="good" onClick={() => approveStylist(item)} />}
                    {item.status === 'pending' && <ActionButton icon={X} label="拒絕" tone="danger" onClick={() => rejectStylist(item)} />}
                    {item.status === 'approved' && <ActionButton icon={EyeOff} label="下架" tone="warn" onClick={() => hideStylist(item)} />}
                  </>
                }
              />
            ))}
            {!stylistApplications.length && <EmptyLine text="沒有符合條件的髮型師申請。" />}
          </div>
        </div>

        <div className="panel">
          <PanelTitle icon={Store} title="沙龍申請" count={salonApplications.length} />
          <div className="record-list">
            {salonApplications.map((item) => (
              <ApplicationCard
                key={item.id}
                image={item.image_url}
                title={item.name}
                subtitle={`${item.brand_name || item.name}${item.branch_name ? ` · ${item.branch_name}` : ''} · ${item.phone || '未填電話'}`}
                status={item.status}
                chips={[
                  item.services_payload?.length ? `${item.services_payload.length} 項服務` : '未填服務',
                  item.instagram_url ? 'IG 已提供' : '',
                  item.open_hours,
                  `HK$${item.start_price}`,
                  ...item.tags.slice(0, 3),
                ]}
                onView={() => setDetail({ kind: 'salonApplication', item })}
                actions={
                  <>
                    {item.status === 'pending' && <ActionButton icon={Check} label="批准" tone="good" onClick={() => approveSalon(item)} />}
                    {item.status === 'pending' && <ActionButton icon={X} label="拒絕" tone="danger" onClick={() => rejectSalon(item)} />}
                    {item.status === 'approved' && <ActionButton icon={EyeOff} label="下架" tone="warn" onClick={() => hideSalon(item)} />}
                  </>
                }
              />
            ))}
            {!salonApplications.length && <EmptyLine text="沒有符合條件的沙龍申請。" />}
          </div>
        </div>
      </div>
    </div>
  );
}

function Catalog({
  data,
  query,
  setDetail,
  updateStylist,
  updateSalon,
  setStylistVisibility,
  setSalonVisibility,
  setRanking,
  repairExposure,
}: {
  data: AdminData;
  query: string;
  setDetail: (detail: DetailTarget) => void;
  updateStylist: (id: string, payload: Partial<Stylist>) => void;
  updateSalon: (id: string, payload: Partial<Salon>) => void;
  setStylistVisibility: (id: string, active: boolean) => void;
  setSalonVisibility: (id: string, active: boolean) => void;
  setRanking: (type: 'stylist' | 'salon', id: string, rank: number | null) => void;
  repairExposure: () => void;
}) {
  const [visibilityFilter, setVisibilityFilter] = useState<CatalogVisibilityFilter>('active');
  const stylists = filterCatalogByVisibility(filterCatalog(data.stylists, query), visibilityFilter);
  const salons = filterCatalogByVisibility(filterCatalog(data.salons, query), visibilityFilter);
  const exposureIssues = findHiddenExposureIssues(data);
  const totalIssues = exposureIssues.homepage + exposureIssues.ranking + exposureIssues.featured;

  return (
    <div className="stack">
      <div className="section-head">
        <div>
          <p className="eyebrow">CATALOG OPS</p>
          <h2>髮型師 / 沙龍檔案管理</h2>
        </div>
        <Segmented
          value={visibilityFilter}
          onChange={(value) => setVisibilityFilter(value as CatalogVisibilityFilter)}
          options={[
            ['active', `上架中 ${countVisible(data.stylists, data.salons, 'active')}`],
            ['hidden', `已下架 ${countVisible(data.stylists, data.salons, 'hidden')}`],
            ['featured', `推薦 ${countVisible(data.stylists, data.salons, 'featured')}`],
            ['all', `全部 ${data.stylists.length + data.salons.length}`],
          ]}
        />
      </div>

      {totalIssues > 0 && (
        <div className="warning-card">
          <div>
            <strong>發現 {totalIssues} 個下架曝光殘留</strong>
            <p>有已下架檔案仍存在首頁位或排行榜。按下修復後會隱藏相關曝光，不會刪除原始檔案。</p>
          </div>
          <button className="primary compact" onClick={repairExposure}>一鍵修復</button>
        </div>
      )}

      <div className="two-col">
        <div className="panel">
          <PanelTitle icon={Scissors} title={`髮型師檔案 · ${visibilityLabel(visibilityFilter)}`} count={stylists.length} />
          <div className="record-list">
            {stylists.map((item) => (
              <CatalogCard
                key={item.id}
                image={item.avatar_url}
                title={item.name}
                subtitle={`${item.title} · ${item.phone || '未填電話'}`}
                active={item.is_active}
                featured={item.is_featured}
                order={item.display_order}
                mediaCounts={catalogMediaCounts(data.works.filter((work) => work.stylist_id === item.id && work.is_active !== false))}
                onView={() => setDetail({ kind: 'stylist', item })}
                onToggleActive={() => setStylistVisibility(item.id, !item.is_active)}
                onToggleFeatured={() => updateStylist(item.id, { is_featured: !item.is_featured })}
                onMove={(delta) => updateStylist(item.id, { display_order: Math.max(1, item.display_order + delta) })}
                onRank={(rank) => setRanking('stylist', item.id, rank)}
              />
            ))}
            {!stylists.length && <EmptyLine text="沒有符合條件的髮型師檔案。" />}
          </div>
        </div>
        <div className="panel">
          <PanelTitle icon={Store} title={`沙龍檔案 · ${visibilityLabel(visibilityFilter)}`} count={salons.length} />
          <div className="record-list">
            {salons.map((item) => (
              <CatalogCard
                key={item.id}
                image={item.image_url}
                title={item.name}
                subtitle={`${item.branch_name || item.location} · HK$${item.start_price}`}
                active={item.is_active}
                featured={item.is_featured}
                order={item.display_order}
                mediaCounts={catalogMediaCounts(data.salonWorks.filter((work) => work.salon_id === item.id && work.is_active !== false))}
                onView={() => setDetail({ kind: 'salon', item })}
                onToggleActive={() => setSalonVisibility(item.id, !item.is_active)}
                onToggleFeatured={() => updateSalon(item.id, { is_featured: !item.is_featured })}
                onMove={(delta) => updateSalon(item.id, { display_order: Math.max(1, item.display_order + delta) })}
                onRank={(rank) => setRanking('salon', item.id, rank)}
              />
            ))}
            {!salons.length && <EmptyLine text="沒有符合條件的沙龍檔案。" />}
          </div>
        </div>
      </div>
    </div>
  );
}

function ContentModeration({
  data,
  query,
  setDetail,
  updateInspiration,
  deleteInspiration,
  repairBrokenInspirations,
  toggleComment,
  updateReport,
}: {
  data: AdminData;
  query: string;
  setDetail: (detail: DetailTarget) => void;
  updateInspiration: (id: string, payload: Partial<InspirationItem>) => void;
  deleteInspiration: (item: InspirationItem) => void;
  repairBrokenInspirations: () => void;
  toggleComment: (item: InspirationComment) => void;
  updateReport: (report: Report, status: ReportStatus) => void;
}) {
  const [contentFilter, setContentFilter] = useState<ContentVisibilityFilter>('active');
  const filteredInspirationSource = filterCatalog(data.inspirations, query);
  const inspirations = filterInspirationsByVisibility(filteredInspirationSource, contentFilter);
  const comments = filterCatalog(data.comments, query).slice(0, 80);
  const reports = filterCatalog(data.reports, query);
  const brokenCount = data.inspirations.filter(hasBrokenInspirationMedia).length;

  return (
    <div className="stack">
      <div className="section-head">
        <div>
          <p className="eyebrow">UGC SAFETY</p>
          <h2>靈感內容 / 留言 / 檢舉</h2>
        </div>
        <Segmented
          value={contentFilter}
          onChange={(value) => setContentFilter(value as ContentVisibilityFilter)}
          options={[
            ['active', `公開 ${data.inspirations.filter((item) => item.is_active).length}`],
            ['hidden', `已隱藏 ${data.inspirations.filter((item) => !item.is_active).length}`],
            ['featured', `推薦 ${data.inspirations.filter((item) => item.is_active && item.is_featured).length}`],
            ['broken', `壞圖 ${brokenCount}`],
            ['all', `全部 ${data.inspirations.length}`],
          ]}
        />
      </div>

      {brokenCount > 0 && (
        <div className="warning-card">
          <div>
            <strong>發現 {brokenCount} 個靈感內容可能有壞圖</strong>
            <p>包括空 URL、本機 file:// 路徑或已知失效圖片。你可以先用「壞圖」篩選查看，或一鍵隱藏避免 App 顯示灰格。</p>
          </div>
          <button className="primary compact" onClick={repairBrokenInspirations}>一鍵隱藏壞圖</button>
        </div>
      )}

      <div className="three-col">
        <div className="panel tall">
          <PanelTitle icon={Sparkles} title="靈感貼文" count={inspirations.length} />
          <div className="record-list">
            {inspirations.map((item) => (
              <ApplicationCard
                key={item.id}
                image={primaryMedia(item)}
                title={item.title}
                subtitle={`${item.author_name || '匿名'} · 排序 ${item.display_order ?? 100} · ${item.comment_count} 評論 · ${item.like_count} 喜歡`}
                status={item.is_active ? 'approved' : 'hidden'}
                chips={[item.location, hasBrokenInspirationMedia(item) ? '壞圖/待整理' : '', item.is_featured ? '推薦' : '', ...(item.tags ?? []).slice(0, 2)]}
                onView={() => setDetail({ kind: 'inspiration', item })}
                actions={
                  <>
                    <ActionButton icon={item.is_active ? EyeOff : Eye} label={item.is_active ? '隱藏' : '恢復'} tone="warn" onClick={() => updateInspiration(item.id, { is_active: !item.is_active })} />
                    <ActionButton icon={Star} label={item.is_featured ? '取消推薦' : '推薦'} tone="neutral" onClick={() => updateInspiration(item.id, { is_featured: !item.is_featured })} />
                    <ActionButton icon={ArrowUp} label="提前" tone="neutral" onClick={() => updateInspiration(item.id, { display_order: Math.max(1, (item.display_order ?? 100) - 10) })} />
                    <ActionButton icon={ArrowDown} label="後移" tone="neutral" onClick={() => updateInspiration(item.id, { display_order: (item.display_order ?? 100) + 10 })} />
                    <ActionButton icon={X} label="永久刪除" tone="danger" onClick={() => deleteInspiration(item)} />
                  </>
                }
              />
            ))}
            {!inspirations.length && <EmptyLine text="沒有符合條件的靈感貼文。" />}
          </div>
        </div>

        <div className="panel tall">
          <PanelTitle icon={Image} title="留言管理" count={comments.length} />
          <div className="record-list">
            {comments.map((item) => (
              <div className="comment-row" key={item.id}>
                <div>
                  <strong>{item.author_name}</strong>
                  <p>{item.body}</p>
                  <span>{formatDate(item.created_at)} · {item.is_hidden ? '已隱藏' : '公開'}</span>
                </div>
                <button className="tiny" onClick={() => toggleComment(item)}>
                  {item.is_hidden ? '恢復' : '隱藏'}
                </button>
              </div>
            ))}
          </div>
        </div>

        <div className="panel tall">
          <PanelTitle icon={Flag} title="檢舉" count={reports.length} />
          <div className="record-list">
            {reports.map((item) => (
              <div className="report-row" key={item.id}>
                <button className="row-main" onClick={() => setDetail({ kind: 'report', item })}>
                  <strong>{item.entity_type} · {item.reason}</strong>
                  <span>{item.status} · {formatDate(item.created_at)}</span>
                </button>
                <div className="row-actions">
                  <button className="tiny" onClick={() => updateReport(item, 'reviewing')}>處理中</button>
                  <button className="tiny good" onClick={() => updateReport(item, 'resolved')}>已解決</button>
                  <button className="tiny" onClick={() => updateReport(item, 'dismissed')}>略過</button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function Placement({
  data,
  query,
  addHomepageItem,
  updateHomepageItem,
  setRanking,
}: {
  data: AdminData;
  query: string;
  addHomepageItem: (item: Partial<HomepageItem>) => void;
  updateHomepageItem: (id: string, payload: Partial<HomepageItem>) => void;
  setRanking: (type: 'stylist' | 'salon', id: string, rank: number | null) => void;
}) {
  const [sectionID, setSectionID] = useState('featured_stylists');
  const [itemType, setItemType] = useState<'stylist' | 'salon' | 'inspiration'>('stylist');
  const [itemID, setItemID] = useState('');
  const activeSections = useMemo(() => data.homepageSections.filter((section) => section.is_active), [data.homepageSections]);
  const visibleHomepageItems = useMemo(
    () => data.homepageItems.filter((item) => item.is_active && isValidHomepageTarget(data, item.item_type, item.item_id)),
    [data],
  );
  const candidates = useMemo(() => {
    const pools = [
      ...data.stylists
        .filter((item) => isActiveRecord(item))
        .map((item) => ({ id: item.id, type: 'stylist' as const, title: item.name })),
      ...data.salons
        .filter((item) => isActiveRecord(item))
        .map((item) => ({ id: item.id, type: 'salon' as const, title: item.name })),
      ...data.inspirations
        .filter((item) => isValidHomepageTarget(data, 'inspiration', item.id))
        .map((item) => ({ id: item.id, type: 'inspiration' as const, title: item.title })),
    ];
    return pools.filter((item) => item.title.toLowerCase().includes(query.toLowerCase()) || item.id.toLowerCase().includes(query.toLowerCase()));
  }, [data, query]);

  useEffect(() => {
    if (!activeSections.length) return;
    if (!activeSections.some((section) => section.id === sectionID)) {
      setSectionID(activeSections[0].id);
    }
  }, [activeSections, sectionID]);

  return (
    <div className="stack">
      <div className="section-head">
        <div>
          <p className="eyebrow">PLACEMENT</p>
          <h2>首頁推薦 / 排行榜</h2>
        </div>
      </div>

      <div className="two-col">
        <div className="panel">
          <PanelTitle icon={Home} title="首頁版位" count={visibleHomepageItems.length} />
          <div className="placement-form">
            <select value={sectionID} onChange={(event) => setSectionID(event.target.value)}>
              {activeSections.map((section) => (
                <option key={section.id} value={section.id}>{section.title}</option>
              ))}
            </select>
            <select value={itemType} onChange={(event) => setItemType(event.target.value as 'stylist' | 'salon' | 'inspiration')}>
              <option value="stylist">髮型師</option>
              <option value="salon">沙龍</option>
              <option value="inspiration">靈感</option>
            </select>
            <input value={itemID} onChange={(event) => setItemID(event.target.value)} placeholder="輸入 item id" />
            <button className="primary compact" onClick={() => addHomepageItem({ section_id: sectionID, item_type: itemType, item_id: itemID, sort_order: 100, is_featured: true, is_active: true })}>
              加入
            </button>
          </div>
          <p className="helper-text">只會顯示仍上架、未壞圖、未被下架的項目；舊 Demo 或已刪除資料會自動排除。</p>
          <div className="record-list">
            {activeSections.map((section) => (
              <div className="section-block" key={section.id}>
                <h3>{section.title}</h3>
                {visibleHomepageItems.filter((item) => item.section_id === section.id).map((item) => (
                  <PlacementRow key={item.id} item={item} title={titleForItem(data, item.item_type, item.item_id)} onUpdate={(payload) => updateHomepageItem(item.id, payload)} />
                ))}
                {!visibleHomepageItems.some((item) => item.section_id === section.id) && <EmptyLine text="此版位暫時沒有有效項目。" />}
              </div>
            ))}
          </div>
        </div>

        <div className="panel">
          <PanelTitle icon={BarChart3} title="候選與排行榜" count={candidates.length} />
          <div className="record-list">
            {candidates.slice(0, 80).map((item) => (
              <div className="candidate-row" key={`${item.type}-${item.id}`}>
                <div>
                  <strong>{item.title}</strong>
                  <span>{item.type} · {item.id}</span>
                </div>
                {(item.type === 'stylist' || item.type === 'salon') && (
                  <div className="row-actions">
                    <button className="tiny" onClick={() => { setItemType(item.type); setItemID(item.id); }}>選用</button>
                    <button className="tiny" onClick={() => setRanking(item.type, item.id, 1)}>#1</button>
                    <button className="tiny" onClick={() => setRanking(item.type, item.id, 2)}>#2</button>
                    <button className="tiny" onClick={() => setRanking(item.type, item.id, null)}>清除</button>
                  </div>
                )}
                {item.type === 'inspiration' && (
                  <button className="tiny" onClick={() => { setItemType(item.type); setItemID(item.id); }}>選用</button>
                )}
              </div>
            ))}
            {!candidates.length && <EmptyLine text="沒有符合搜尋條件的有效候選。" />}
          </div>
        </div>
      </div>
    </div>
  );
}

function DetailDrawer({
  detail,
  data,
  onClose,
  approveStylist,
  rejectStylist,
  hideStylist,
  approveSalon,
  rejectSalon,
  hideSalon,
}: {
  detail: DetailTarget;
  data: AdminData;
  onClose: () => void;
  approveStylist: (item: StylistApplication) => void;
  rejectStylist: (item: StylistApplication) => void;
  hideStylist: (item: StylistApplication) => void;
  approveSalon: (item: SalonApplication) => void;
  rejectSalon: (item: SalonApplication) => void;
  hideSalon: (item: SalonApplication) => void;
}) {
  const title = detailTitle(detail);
  const media = detailMedia(detail, data);
  const sections = detailInfoSections(detail);
  const services = detailServices(detail, data);
  const comments = detail.kind === 'inspiration' ? data.comments.filter((item) => item.inspiration_id === detail.item.id) : [];
  const hasApprovalActions = detail.kind === 'stylistApplication' || detail.kind === 'salonApplication';

  return (
    <div className="drawer-backdrop" onClick={onClose}>
      <aside className="drawer" onClick={(event) => event.stopPropagation()}>
        <div className="drawer-head">
          <div>
            <p className="eyebrow">DETAIL</p>
            <h2>{title}</h2>
          </div>
          <button className="icon-btn" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        {hasApprovalActions && (
          <div className="drawer-actions">
            {detail.kind === 'stylistApplication' && detail.item.status === 'pending' && (
              <>
                <ActionButton icon={Check} label="批准髮型師" tone="good" onClick={() => approveStylist(detail.item)} />
                <ActionButton icon={X} label="拒絕申請" tone="danger" onClick={() => rejectStylist(detail.item)} />
              </>
            )}
            {detail.kind === 'stylistApplication' && detail.item.status === 'approved' && (
              <ActionButton icon={EyeOff} label="下架髮型師" tone="warn" onClick={() => hideStylist(detail.item)} />
            )}
            {detail.kind === 'salonApplication' && detail.item.status === 'pending' && (
              <>
                <ActionButton icon={Check} label="批准沙龍" tone="good" onClick={() => approveSalon(detail.item)} />
                <ActionButton icon={X} label="拒絕申請" tone="danger" onClick={() => rejectSalon(detail.item)} />
              </>
            )}
            {detail.kind === 'salonApplication' && detail.item.status === 'approved' && (
              <ActionButton icon={EyeOff} label="下架沙龍" tone="warn" onClick={() => hideSalon(detail.item)} />
            )}
          </div>
        )}

        <div className="detail-summary">
          {sections[0]?.fields.slice(0, 4).map((field) => (
            <div key={field.label}>
              <span>{field.label}</span>
              <strong>{detailValue(field.value)}</strong>
            </div>
          ))}
        </div>

        <div className="detail-section">
          <h3>作品集相片 / 短片</h3>
          {media.length ? (
            <div className="media-grid review-media-grid">
              {media.map((item, index) => (
                <figure key={`${item.imageURL}-${item.videoURL ?? ''}-${index}`} className={item.mediaKind === 'video' ? 'is-video' : ''}>
                  {item.mediaKind === 'video' && item.videoURL ? (
                    <video src={item.videoURL} poster={item.imageURL || undefined} controls preload="metadata" />
                  ) : (
                    <img src={item.imageURL || fallbackImage()} alt={item.title} onError={(event) => { event.currentTarget.src = fallbackImage(); }} />
                  )}
                  {item.mediaKind === 'video' && (
                    <span className="media-badge">
                      <Film size={13} />
                      短片
                    </span>
                  )}
                  <figcaption>{item.title}</figcaption>
                </figure>
              ))}
            </div>
          ) : (
            <EmptyLine text="此申請沒有可預覽的作品集媒體。" />
          )}
        </div>

        {sections.map((section) => (
          <div className="detail-section" key={section.title}>
            <h3>{section.title}</h3>
            <DetailFieldGrid fields={section.fields} />
          </div>
        ))}

        {!!services.length && (
          <div className="detail-section">
            <h3>服務項目</h3>
            {services.map((item) => (
              <div className="service-row" key={item.id}>
                <div>
                  <strong>{item.name}</strong>
                  <span>{[item.category, `${item.duration} 分鐘`, item.description].filter(Boolean).join(' · ')}</span>
                </div>
                <b>HK${item.price}</b>
              </div>
            ))}
          </div>
        )}

        {!!comments.length && (
          <div className="detail-section">
            <h3>留言</h3>
            {comments.map((item) => (
              <div className="comment-row" key={item.id}>
                <div>
                  <strong>{item.author_name}</strong>
                  <p>{item.body}</p>
                </div>
                <span>{item.is_hidden ? '已隱藏' : '公開'}</span>
              </div>
            ))}
          </div>
        )}

        <div className="detail-section">
          <h3>原始資料</h3>
          <pre>{JSON.stringify(detail.item, null, 2)}</pre>
        </div>
      </aside>
    </div>
  );
}

function DetailFieldGrid({ fields }: { fields: DetailField[] }) {
  return (
    <div className="detail-fields">
      {fields.map((field) => (
        <div className="detail-field" key={field.label}>
          <span>{field.label}</span>
          <strong>{detailValue(field.value)}</strong>
        </div>
      ))}
    </div>
  );
}

function resolveStylistReplacementTarget(application: StylistApplication, data: AdminData) {
  const ownerCandidates = compactStrings([application.owner_id, application.claimed_by, application.submitted_by]);
  for (const ownerID of ownerCandidates) {
    const ownerMatches = data.stylists.filter((stylist) => stylist.owner_id === ownerID);
    const ownerMatch = pickSingleStylistMatch(ownerMatches, application, '同一髮型師帳號');
    if (ownerMatch) return ownerMatch;
  }

  const exactIDMatch = data.stylists.find((stylist) => stylist.id === application.stylist_id);
  if (exactIDMatch) return exactIDMatch;

  const email = normalizeLookup(application.contact_email);
  if (email) {
    const applicationMatches = data.stylistApplications
      .filter((item) => item.id !== application.id && item.status === 'approved' && normalizeLookup(item.contact_email) === email)
      .map((item) => data.stylists.find((stylist) => stylist.id === item.stylist_id))
      .filter(isStylist);
    const emailMatch = pickSingleStylistMatch(applicationMatches, application, '同一申請 Email');
    if (emailMatch) return emailMatch;
  }

  const phone = normalizePhone(application.phone);
  if (phone) {
    const phoneMatches = data.stylists.filter((stylist) => stylist.is_active && normalizePhone(stylist.phone) === phone);
    const phoneMatch = pickSingleStylistMatch(phoneMatches, application, '同一電話');
    if (phoneMatch) return phoneMatch;
  }

  const instagram = normalizeInstagram(application.instagram_url);
  if (instagram) {
    const instagramMatches = data.stylists.filter((stylist) => stylist.is_active && normalizeInstagram(stylist.instagram_url) === instagram);
    const instagramMatch = pickSingleStylistMatch(instagramMatches, application, '同一 Instagram');
    if (instagramMatch) return instagramMatch;
  }

  return null;
}

function pickSingleStylistMatch(matches: Stylist[], application: StylistApplication, reason: string) {
  const unique = uniqueStylists(matches);
  if (unique.length === 0) return null;
  if (unique.length === 1) return unique[0];

  const exact = unique.find((stylist) => stylist.id === application.stylist_id);
  if (exact) return exact;

  throw new Error(`${reason} 找到多於一個已存在髮型師檔案，請先在檔案頁確認應該保留哪一個。`);
}

function uniqueStylists(items: Stylist[]) {
  const seen = new Set<string>();
  return items.filter((item) => {
    if (seen.has(item.id)) return false;
    seen.add(item.id);
    return true;
  });
}

function compactStrings(values: Array<string | null | undefined>) {
  return Array.from(new Set(values.map((value) => value?.trim()).filter((value): value is string => Boolean(value))));
}

function isStylist(value: Stylist | undefined): value is Stylist {
  return Boolean(value);
}

function normalizeLookup(value: string | null | undefined) {
  return value?.trim().toLowerCase() ?? '';
}

function normalizePhone(value: string | null | undefined) {
  return value?.replace(/\D/g, '') ?? '';
}

function normalizeInstagram(value: string | null | undefined) {
  const clean = normalizeLookup(value);
  if (!clean) return '';
  const withoutProtocol = clean.replace(/^https?:\/\//, '').replace(/^www\./, '');
  const withoutHost = withoutProtocol.replace(/^(instagram\.com|instagr\.am)\//, '');
  return withoutHost.replace(/^@/, '').replace(/\/+$/, '').split(/[/?#]/)[0] ?? '';
}

function resolveSalonBrandID(application: SalonApplication, data: AdminData, brandName: string) {
  const normalizedName = normalizeLookup(brandName);
  const existingBrand = data.salonBrands.find((brand) => normalizeLookup(brand.name) === normalizedName);
  if (existingBrand) return existingBrand.id;

  const existingBranch = data.salons.find((salon) => salon.brand_id && normalizeLookup(salon.name) === normalizedName);
  if (existingBranch?.brand_id) return existingBranch.brand_id;

  return application.salon_id === 'salon-hair-kiss-2ba81bac' || normalizedName === 'hair kiss' || normalizedName === 'hairkiss'
    ? 'hair-kiss'
    : `salon-brand-${stableIDSegment(brandName)}`;
}

function stableIDSegment(value: string) {
  const ascii = value
    .trim()
    .toLowerCase()
    .replace(/&/g, ' and ')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

  if (ascii) return ascii;

  return Array.from(value.trim())
    .map((character) => character.codePointAt(0)?.toString(16))
    .filter(Boolean)
    .join('-');
}

async function approveStylistApplication(application: StylistApplication, userID: string, data: AdminData) {
  const replacement = resolveStylistReplacementTarget(application, data);
  const targetStylistID = replacement?.id ?? application.stylist_id;
  const ownerID = application.owner_id ?? replacement?.owner_id ?? null;
  const salonID =
    replacement && application.salon_id === 'independent-stylist-studio'
      ? replacement.salon_id
      : application.salon_id || replacement?.salon_id || 'independent-stylist-studio';
  const stylist = {
    id: targetStylistID,
    owner_id: ownerID,
    salon_id: salonID,
    district: application.district ?? '',
    location: application.location ?? '',
    name: application.name,
    title: application.title,
    rating: replacement?.rating ?? application.rating,
    reviews_count: replacement?.reviews_count ?? application.reviews_count,
    languages: application.languages,
    experience: application.experience,
    specialties: application.specialties ?? [],
    avatar_url: application.avatar_url,
    phone: application.phone ?? '',
    instagram_url: application.instagram_url ?? '',
    bio: application.bio ?? '',
    base_price: application.base_price,
    is_active: true,
    is_featured: replacement?.is_featured ?? false,
    display_order: replacement?.display_order ?? 100,
  };

  await assertOk(supabase.from('stylists').upsert(stylist, { onConflict: 'id' }));
  await assertOk(supabase.from('services').delete().eq('stylist_id', targetStylistID));

  const services = normalizeServices(application.services_payload, targetStylistID);
  if (services.length) await assertOk(supabase.from('services').insert(services));

  await assertOk(supabase.from('portfolio_works').delete().eq('stylist_id', targetStylistID));
  const works = normalizeWorks(application.works_payload, targetStylistID);
  if (works.length) await assertOk(supabase.from('portfolio_works').insert(works));

  await updateStylistApplicationStatus(application, 'approved', userID, {
    stylist_id: targetStylistID,
    owner_id: ownerID,
  });
  if (ownerID) {
    await assertOk(
      supabase
        .from('profiles')
        .update({
          display_name: application.name,
          stylist_id: targetStylistID,
          avatar_url: application.avatar_url,
        })
        .eq('id', ownerID),
    );
  }
}

async function approveSalonApplication(application: SalonApplication, userID: string, data: AdminData) {
  const brandName = (application.brand_name || application.name).trim();
  const branchName = (application.branch_name || application.district || application.location).trim();
  const brandID = brandName ? resolveSalonBrandID(application, data, brandName) : null;

  if (brandID) {
    await assertOk(
      supabase.from('salon_brands').upsert(
        {
          id: brandID,
          name: brandName,
          primary_salon_id: application.salon_id,
          description: branchName ? `${brandName} · ${branchName}` : brandName,
          image_url: application.image_url,
          instagram_url: application.instagram_url ?? '',
          phone: application.phone ?? '',
          is_active: true,
          display_order: 100,
        },
        { onConflict: 'id' },
      ),
    );
  }

  const salon = {
    id: application.salon_id,
    brand_id: brandID,
    branch_name: branchName,
    name: application.name,
    location: application.location,
    district: application.district ?? '',
    distance: application.distance,
    rating: application.rating,
    tags: application.tags ?? [],
    open_hours: application.open_hours,
    phone: application.phone,
    instagram_url: application.instagram_url ?? '',
    start_price: application.start_price,
    image_url: application.image_url,
    is_active: true,
    is_featured: false,
    display_order: 100,
    booking_enabled: true,
    chat_enabled: true,
  };

  await assertOk(supabase.from('salons').upsert(salon, { onConflict: 'id' }));
  await assertOk(supabase.from('salon_portfolio_works').delete().eq('salon_id', application.salon_id));

  const works = normalizeSalonWorks(application.works_payload, application.salon_id);
  if (works.length) await assertOk(supabase.from('salon_portfolio_works').insert(works));

  await assertOk(supabase.from('salon_services').delete().eq('salon_id', application.salon_id));
  const services = normalizeSalonServices(application.services_payload, application.salon_id);
  if (services.length) await assertOk(supabase.from('salon_services').insert(services));

  await updateSalonApplicationStatus(application, 'approved', userID);
}

async function hideStylistApplication(application: StylistApplication, userID: string) {
  await setCatalogVisibility('stylist', application.stylist_id, false, userID);
  await updateStylistApplicationStatus(application, 'hidden', userID);
}

async function hideSalonApplication(application: SalonApplication, userID: string) {
  await setCatalogVisibility('salon', application.salon_id, false, userID);
  await updateSalonApplicationStatus(application, 'hidden', userID);
}

async function updateStylistApplicationStatus(
  application: StylistApplication,
  status: ApplicationStatus,
  userID: string,
  extra: Partial<Pick<StylistApplication, 'stylist_id' | 'owner_id'>> = {},
) {
  const note = status === 'rejected' ? window.prompt('拒絕原因或 admin note，可留空') ?? application.admin_note : application.admin_note;
  await assertOk(
    supabase
      .from('stylist_applications')
      .update({ status, admin_note: note, reviewed_by: userID, reviewed_at: new Date().toISOString(), ...extra })
      .eq('id', application.id),
  );
}

async function updateSalonApplicationStatus(application: SalonApplication, status: ApplicationStatus, userID: string) {
  const note = status === 'rejected' ? window.prompt('拒絕原因或 admin note，可留空') ?? application.admin_note : application.admin_note;
  await assertOk(
    supabase
      .from('salon_applications')
      .update({ status, admin_note: note, reviewed_by: userID, reviewed_at: new Date().toISOString() })
      .eq('id', application.id),
  );
}

async function updateTable(table: string, id: string, payload: Record<string, unknown>) {
  await assertOk(supabase.from(table).update(payload).eq('id', id));
}

async function updateHomepageItemRecord(data: AdminData, id: string, payload: Partial<HomepageItem>) {
  const current = data.homepageItems.find((item) => item.id === id);
  if (!current) throw new Error('找不到此首頁項目，請刷新後再試。');

  if (payload.is_active !== false) {
    const nextType = payload.item_type ?? current.item_type;
    const nextID = payload.item_id ?? current.item_id;
    if (!isValidHomepageTarget(data, nextType, nextID)) {
      throw new Error('此項目已下架、已刪除或圖片失效，不能重新啟用到首頁。');
    }
  }

  await updateTable('homepage_items', id, payload);
}

async function setCatalogVisibility(type: CatalogEntityType, id: string, active: boolean, userID: string) {
  const table = type === 'stylist' ? 'stylists' : 'salons';
  const applicationTable = type === 'stylist' ? 'stylist_applications' : 'salon_applications';
  const applicationIDColumn = type === 'stylist' ? 'stylist_id' : 'salon_id';
  const hiddenPayload = { is_active: false, is_featured: false, display_order: 999 };
  const activePayload = { is_active: true };

  await assertOk(supabase.from(table).update(active ? activePayload : hiddenPayload).eq('id', id));
  await assertOk(
    supabase
      .from(applicationTable)
      .update({
        status: active ? 'approved' : 'hidden',
        reviewed_by: userID,
        reviewed_at: new Date().toISOString(),
      })
      .eq(applicationIDColumn, id)
      .in('status', active ? ['hidden'] : ['pending', 'approved']),
  );

  if (!active) {
    await clearCatalogExposure(type, id);
  }
}

async function clearCatalogExposure(type: CatalogEntityType, id: string) {
  await Promise.all([
    assertOk(
      supabase
        .from('homepage_items')
        .update({ is_active: false, is_featured: false })
        .eq('item_type', type)
        .eq('item_id', id),
    ),
    assertOk(
      supabase
        .from('ranking_overrides')
        .update({ is_active: false, is_pinned: false, manual_rank: null })
        .eq('item_type', type)
        .eq('item_id', id),
    ),
  ]);
}

async function clearInspirationExposure(id: string) {
  await Promise.all([
    assertOk(
      supabase
        .from('homepage_items')
        .update({ is_active: false, is_featured: false })
        .eq('item_type', 'inspiration')
        .eq('item_id', id),
    ),
    assertOk(
      supabase
        .from('inspiration_items')
        .update({ is_featured: false, display_order: 999 })
        .eq('id', id)
        .eq('is_active', false),
    ),
  ]);
}

async function repairHiddenExposure(data: AdminData) {
  const hiddenStylists = data.stylists.filter((item) => !item.is_active).map((item) => item.id);
  const hiddenSalons = data.salons.filter((item) => !item.is_active).map((item) => item.id);
  const hiddenInspirations = data.inspirations.filter((item) => !item.is_active || hasBrokenInspirationMedia(item)).map((item) => item.id);
  const invalidHomepageIDs = data.homepageItems
    .filter((item) => item.is_active && !isValidHomepageTarget(data, item.item_type, item.item_id))
    .map((item) => item.id);
  const invalidRankingIDs = data.rankingOverrides
    .filter((item) => item.is_active && !isValidRankingTarget(data, item.item_type, item.item_id))
    .map((item) => item.id);
  const tasks: Promise<void>[] = [
    ...hiddenStylists.map((id) => clearCatalogExposure('stylist', id)),
    ...hiddenSalons.map((id) => clearCatalogExposure('salon', id)),
    ...hiddenInspirations.map((id) => clearInspirationExposure(id)),
  ];

  if (hiddenStylists.length) {
    tasks.push(assertOk(supabase.from('stylists').update({ is_featured: false, display_order: 999 }).in('id', hiddenStylists)));
  }
  if (hiddenSalons.length) {
    tasks.push(assertOk(supabase.from('salons').update({ is_featured: false, display_order: 999 }).in('id', hiddenSalons)));
  }
  if (hiddenInspirations.length) {
    tasks.push(assertOk(supabase.from('inspiration_items').update({ is_featured: false, display_order: 999 }).in('id', hiddenInspirations)));
  }
  if (invalidHomepageIDs.length) {
    tasks.push(assertOk(supabase.from('homepage_items').update({ is_active: false, is_featured: false }).in('id', invalidHomepageIDs)));
  }
  if (invalidRankingIDs.length) {
    tasks.push(assertOk(supabase.from('ranking_overrides').update({ is_active: false, is_pinned: false, manual_rank: null }).in('id', invalidRankingIDs)));
  }

  await Promise.all(tasks);
}

async function updateReportStatus(report: Report, status: ReportStatus, userID: string) {
  await assertOk(
    supabase
      .from('reports')
      .update({
        status,
        resolved_by: status === 'resolved' || status === 'dismissed' ? userID : null,
        resolved_at: status === 'resolved' || status === 'dismissed' ? new Date().toISOString() : null,
      })
      .eq('id', report.id),
  );
}

async function deleteInspiration(item: InspirationItem) {
  if (!window.confirm(`確定要永久刪除「${item.title}」？此動作會同步清走留言、喜歡、收藏/分享、首頁推薦及相關曝光，不能復原。`)) return;

  await Promise.all([
    assertOk(supabase.from('homepage_items').update({ is_active: false, is_featured: false }).eq('item_type', 'inspiration').eq('item_id', item.id)),
    assertOk(supabase.from('reports').update({ status: 'resolved', resolved_at: new Date().toISOString() }).eq('entity_type', 'inspiration').eq('entity_id', item.id)),
  ]);

  await assertOk(supabase.from('inspiration_items').delete().eq('id', item.id));
}

async function repairBrokenInspirations(data: AdminData) {
  const brokenIDs = data.inspirations.filter(hasBrokenInspirationMedia).map((item) => item.id);
  if (!brokenIDs.length) return;
  await Promise.all([
    assertOk(supabase.from('inspiration_items').update({ is_active: false, is_featured: false, display_order: 999 }).in('id', brokenIDs)),
    assertOk(supabase.from('homepage_items').update({ is_active: false, is_featured: false }).eq('item_type', 'inspiration').in('item_id', brokenIDs)),
  ]);
}

async function upsertHomepageItem(item: Partial<HomepageItem>, data: AdminData) {
  if (!item.section_id || !item.item_type || !item.item_id) throw new Error('請先填 section、類型及 item id。');
  const itemID = item.item_id.trim();
  const section = data.homepageSections.find((sectionItem) => sectionItem.id === item.section_id);
  if (!section?.is_active) throw new Error('此首頁版位不存在或已停用。');
  if (!isValidHomepageTarget(data, item.item_type, itemID)) {
    throw new Error('此項目不存在、已下架或圖片失效，不能加入首頁。');
  }

  await assertOk(
    supabase.from('homepage_items').upsert(
      {
        ...item,
        item_id: itemID,
        sort_order: item.sort_order ?? 100,
        is_featured: item.is_featured ?? true,
        is_active: true,
      },
      { onConflict: 'section_id,item_type,item_id' },
    ),
  );
}

async function upsertRanking(type: 'stylist' | 'salon', id: string, rank: number | null, data: AdminData) {
  const itemID = id.trim();
  if (rank !== null) {
    if (!isValidRankingTarget(data, type, itemID)) throw new Error('已下架或不存在的檔案不能加入排行榜，請先上架。');
  }

  const rankingKey = type === 'stylist' ? 'stylist_hot' : 'salon_hot';
  if (rank === null) {
    await assertOk(
      supabase
        .from('ranking_overrides')
        .update({ manual_rank: null, is_pinned: false, is_active: false, note: 'Admin 清除手動排序' })
        .eq('ranking_key', rankingKey)
        .eq('item_type', type)
        .eq('item_id', itemID),
    );
    return;
  }

  await assertOk(
    supabase.from('ranking_overrides').upsert(
      {
        ranking_key: rankingKey,
        item_type: type,
        item_id: itemID,
        manual_rank: rank,
        is_pinned: true,
        is_active: true,
        note: `Admin 手動置頂 #${rank}`,
      },
      { onConflict: 'ranking_key,item_type,item_id' },
    ),
  );
}

async function assertOk<T>(promise: PromiseLike<{ error: unknown; data?: T }>) {
  const { error } = await promise;
  if (error) throw error;
}

function normalizeServices(items: ServiceItem[] | null | undefined, stylistID: string) {
  return (items ?? []).map((item, index) => ({
    id: item.id || `${stylistID}-service-${index + 1}`,
    stylist_id: stylistID,
    name: item.name,
    category: item.category || '剪髮',
    duration: Number(item.duration || 60),
    description: item.description || '',
    price: Number(item.price || 0),
    is_active: true,
    display_order: (index + 1) * 10,
  }));
}

function normalizeWorks(items: PortfolioWork[] | null | undefined, stylistID: string) {
  return (items ?? []).filter((item) => isUsableRemoteMediaURL(item.image_url)).map((item, index) => ({
    id: item.id || `${stylistID}-work-${index + 1}`,
    stylist_id: stylistID,
    title: item.title || `作品 ${index + 1}`,
    image_url: item.image_url,
    media_kind: item.media_kind === 'video' ? 'video' : 'photo',
    video_url: item.media_kind === 'video' ? item.video_url ?? '' : '',
    thumbnail_url: item.thumbnail_url || item.image_url,
    is_active: true,
    display_order: (index + 1) * 10,
  }));
}

function normalizeSalonWorks(items: PortfolioWork[] | null | undefined, salonID: string) {
  return (items ?? []).filter((item) => isUsableRemoteMediaURL(item.image_url)).map((item, index) => ({
    id: item.id || `${salonID}-work-${index + 1}`,
    salon_id: salonID,
    title: item.title || `沙龍作品 ${index + 1}`,
    image_url: item.image_url,
    media_kind: item.media_kind === 'video' ? 'video' : 'photo',
    video_url: item.media_kind === 'video' ? item.video_url ?? '' : '',
    thumbnail_url: item.thumbnail_url || item.image_url,
    is_active: true,
    display_order: (index + 1) * 10,
  }));
}

function normalizeSalonServices(items: SalonServiceItem[] | null | undefined, salonID: string) {
  return (items ?? []).map((item, index) => ({
    id: item.id || `${salonID}-service-${index + 1}`,
    salon_id: salonID,
    name: item.name,
    category: item.category || '剪髮',
    duration: Number(item.duration || 60),
    description: item.description || '',
    price: Number(item.price || 0),
    is_active: true,
    display_order: (index + 1) * 10,
  }));
}

function catalogMediaCounts(items: Array<PortfolioWork | SalonWork>): DetailMediaCounts {
  const media = items
    .map((item, index) => workMedia(item, index, '作品'))
    .filter(Boolean) as DetailMediaItem[];
  return {
    total: media.length,
    videos: media.filter((item) => item.mediaKind === 'video').length,
  };
}

function Metric({ title, value, icon: Icon, onClick }: { title: string; value: number; icon: LucideIcon; onClick: () => void }) {
  return (
    <button className="metric" onClick={onClick}>
      <Icon size={22} />
      <span>{title}</span>
      <strong>{value}</strong>
    </button>
  );
}

function PanelTitle({ icon: Icon, title, count }: { icon: LucideIcon; title: string; count: number }) {
  return (
    <div className="panel-title">
      <h3>
        <Icon size={17} />
        {title}
      </h3>
      <span>{count}</span>
    </div>
  );
}

function ApplicationCard({
  image,
  title,
  subtitle,
  status,
  chips,
  actions,
  onView,
}: {
  image: string;
  title: string;
  subtitle: string;
  status: ApplicationStatus;
  chips: string[];
  actions: ReactNode;
  onView: () => void;
}) {
  return (
    <article className="record-card">
      <img src={image || fallbackImage()} alt={title} onError={(event) => { event.currentTarget.src = fallbackImage(); }} />
      <div className="record-body">
        <div className="record-title">
          <button onClick={onView}>{title}</button>
          <StatusPill status={status} />
        </div>
        <p>{subtitle}</p>
        <div className="chip-row">
          {chips.filter(Boolean).slice(0, 5).map((chip) => <span key={chip}>{chip}</span>)}
        </div>
        <div className="action-row">
          <button className="tiny" onClick={onView}>
            <Eye size={14} />
            查看完整內容
          </button>
          {actions}
        </div>
      </div>
    </article>
  );
}

function CatalogCard({
  image,
  title,
  subtitle,
  active,
  featured,
  order,
  mediaCounts,
  onView,
  onToggleActive,
  onToggleFeatured,
  onMove,
  onRank,
}: {
  image: string;
  title: string;
  subtitle: string;
  active: boolean;
  featured: boolean;
  order: number;
  mediaCounts: DetailMediaCounts;
  onView: () => void;
  onToggleActive: () => void;
  onToggleFeatured: () => void;
  onMove: (delta: number) => void;
  onRank: (rank: number | null) => void;
}) {
  return (
    <article className="catalog-card">
      <img src={image || fallbackImage()} alt={title} onError={(event) => { event.currentTarget.src = fallbackImage(); }} />
      <div>
        <button className="title-link" onClick={onView}>{title}</button>
        <p>{subtitle}</p>
        <div className="chip-row">
          <span>排序 {order}</span>
          <span>{active ? '上架中' : '已下架'}</span>
          <span>{featured ? '首頁推薦' : '非推薦'}</span>
          <span>作品 {mediaCounts.total}</span>
          {mediaCounts.videos > 0 && <span>短片 {mediaCounts.videos}</span>}
        </div>
        <div className="action-row">
          <button className="tiny good" onClick={onView}><Eye size={13} />查看詳情</button>
          <button className="tiny" onClick={onToggleActive}>{active ? '下架' : '上架'}</button>
          <button className="tiny" disabled={!active} onClick={onToggleFeatured}>{featured ? '取消推薦' : '推薦'}</button>
          <button className="tiny" disabled={!active} onClick={() => onMove(-10)}><ArrowUp size={13} />提前</button>
          <button className="tiny" disabled={!active} onClick={() => onMove(10)}><ArrowDown size={13} />後移</button>
          <button className="tiny" disabled={!active} onClick={() => onRank(1)}>排行 #1</button>
          <button className="tiny" onClick={() => onRank(null)}>清排行</button>
        </div>
      </div>
    </article>
  );
}

function PlacementRow({ item, title, onUpdate }: { item: HomepageItem; title: string; onUpdate: (payload: Partial<HomepageItem>) => void }) {
  return (
    <div className="placement-row">
      <div>
        <strong>{title}</strong>
        <span>{item.item_type} · {item.item_id} · 排序 {item.sort_order}</span>
      </div>
      <div className="row-actions">
        <button className="tiny warn" onClick={() => onUpdate({ is_active: false, is_featured: false })}>移除</button>
        <button className="tiny" onClick={() => onUpdate({ is_featured: !item.is_featured })}>{item.is_featured ? '取消精選' : '精選'}</button>
        <button className="tiny" onClick={() => onUpdate({ sort_order: Math.max(1, item.sort_order - 10) })}>提前</button>
        <button className="tiny" onClick={() => onUpdate({ sort_order: item.sort_order + 10 })}>後移</button>
      </div>
    </div>
  );
}

function ActionButton({ icon: Icon, label, tone, onClick }: { icon: LucideIcon; label: string; tone: 'good' | 'danger' | 'warn' | 'neutral'; onClick: () => void }) {
  return (
    <button className={`tiny ${tone}`} onClick={onClick}>
      <Icon size={13} />
      {label}
    </button>
  );
}

function StatusPill({ status }: { status: ApplicationStatus }) {
  return <span className={`status ${status}`}>{statusLabel(status)}</span>;
}

function Segmented({ value, onChange, options }: { value: string; onChange: (value: string) => void; options: [string, string][] }) {
  return (
    <div className="segmented">
      {options.map(([id, label]) => (
        <button key={id} className={value === id ? 'active' : ''} onClick={() => onChange(id)}>
          {label}
        </button>
      ))}
    </div>
  );
}

function MiniRow({ title, meta, onClick }: { title: string; meta: string; onClick: () => void }) {
  return (
    <button className="mini-row" onClick={onClick}>
      <div>
        <strong>{title}</strong>
        <span>{meta}</span>
      </div>
      <ChevronRight size={17} />
    </button>
  );
}

function EmptyLine({ text }: { text: string }) {
  return <p className="empty-line">{text}</p>;
}

function ToastView({ toast, onClose }: { toast: Toast; onClose: () => void }) {
  return (
    <div className={`toast ${toast.type}`}>
      {toast.type === 'success' ? <BadgeCheck size={18} /> : toast.type === 'error' ? <AlertTriangle size={18} /> : <Shield size={18} />}
      <span>{toast.message}</span>
      <button onClick={onClose}><X size={15} /></button>
    </div>
  );
}

function filterApplications<T extends { status: ApplicationStatus }>(items: T[], query: string, status: ApplicationStatus | 'all') {
  return filterCatalog(items.filter((item) => status === 'all' || item.status === status), query);
}

function latestApplications<T extends { created_at: string }>(items: T[], keyForItem: (item: T) => string) {
  const seen = new Set<string>();
  return [...items]
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    .filter((item) => {
      const key = keyForItem(item);
      if (!key || seen.has(key)) return false;
      seen.add(key);
      return true;
    });
}

function filterCatalogByVisibility<T extends { is_active: boolean; is_featured: boolean }>(items: T[], status: CatalogVisibilityFilter) {
  switch (status) {
    case 'active':
      return items.filter((item) => item.is_active);
    case 'hidden':
      return items.filter((item) => !item.is_active);
    case 'featured':
      return items.filter((item) => item.is_active && item.is_featured);
    case 'all':
      return items;
  }
}

function filterInspirationsByVisibility(items: InspirationItem[], status: ContentVisibilityFilter) {
  switch (status) {
    case 'active':
      return items.filter((item) => item.is_active);
    case 'hidden':
      return items.filter((item) => !item.is_active);
    case 'featured':
      return items.filter((item) => item.is_active && item.is_featured);
    case 'broken':
      return items.filter(hasBrokenInspirationMedia);
    case 'all':
      return items;
  }
}

function countVisible(stylists: Stylist[], salons: Salon[], status: CatalogVisibilityFilter) {
  return filterCatalogByVisibility([...stylists, ...salons], status).length;
}

function visibilityLabel(status: CatalogVisibilityFilter) {
  switch (status) {
    case 'active':
      return '上架中';
    case 'hidden':
      return '已下架';
    case 'featured':
      return '推薦';
    case 'all':
      return '全部';
  }
}

function findHiddenExposureIssues(data: AdminData) {
  return {
    homepage: data.homepageItems.filter((item) => item.is_active && !isValidHomepageTarget(data, item.item_type, item.item_id)).length,
    ranking: data.rankingOverrides.filter((item) => item.is_active && !isValidRankingTarget(data, item.item_type, item.item_id)).length,
    featured:
      data.stylists.filter((item) => !item.is_active && item.is_featured).length +
      data.salons.filter((item) => !item.is_active && item.is_featured).length +
      data.inspirations.filter((item) => item.is_featured && (!item.is_active || hasBrokenInspirationMedia(item))).length,
  };
}

function filterCatalog<T>(items: T[], query: string) {
  const normalized = query.trim().toLowerCase();
  if (!normalized) return items;
  return items.filter((item) => JSON.stringify(item).toLowerCase().includes(normalized));
}

function titleForItem(data: AdminData, type: string, id: string) {
  if (type === 'stylist') return data.stylists.find((item) => item.id === id)?.name ?? id;
  if (type === 'salon') return data.salons.find((item) => item.id === id)?.name ?? id;
  return data.inspirations.find((item) => item.id === id)?.title ?? id;
}

function isActiveRecord(item: { is_active?: boolean } | null | undefined) {
  return Boolean(item) && item?.is_active !== false;
}

function findHomepageTarget(data: AdminData, type: PlacementItemType, id: string) {
  if (type === 'stylist') return data.stylists.find((item) => item.id === id) ?? null;
  if (type === 'salon') return data.salons.find((item) => item.id === id) ?? null;
  return data.inspirations.find((item) => item.id === id) ?? null;
}

function isValidHomepageTarget(data: AdminData, type: PlacementItemType, id: string) {
  const target = findHomepageTarget(data, type, id.trim());
  if (!isActiveRecord(target)) return false;
  if (type === 'inspiration') return !hasBrokenInspirationMedia(target as InspirationItem);
  return true;
}

function isValidRankingTarget(data: AdminData, type: RankingItemType, id: string) {
  if (type === 'stylist') return isActiveRecord(data.stylists.find((item) => item.id === id.trim()));
  return isActiveRecord(data.salons.find((item) => item.id === id.trim()));
}

function primaryMedia(item: InspirationItem) {
  return validInspirationMediaURLs(item)[0] || fallbackImage();
}

function detailTitle(detail: DetailTarget) {
  switch (detail.kind) {
    case 'stylistApplication':
    case 'stylist':
      return detail.item.name;
    case 'salonApplication':
    case 'salon':
      return detail.item.name;
    case 'inspiration':
      return detail.item.title;
    case 'report':
      return `${detail.item.entity_type} 檢舉`;
  }
}

function detailInfoSections(detail: DetailTarget): DetailSection[] {
  switch (detail.kind) {
    case 'stylistApplication':
      return [
        {
          title: '審批狀態',
          fields: [
            { label: '狀態', value: statusLabel(detail.item.status) },
            { label: '提交時間', value: formatDateSafe(detail.item.created_at) },
            { label: '申請 ID', value: detail.item.id },
            { label: '髮型師 ID', value: detail.item.stylist_id },
            { label: '自動連接', value: detail.item.claimed_by ? '已連接 App 帳號' : '批准後等待同 email 註冊' },
            { label: '已連接帳號', value: detail.item.claimed_by },
            { label: '連接時間', value: formatDateSafe(detail.item.claimed_at) },
            { label: 'Admin note', value: detail.item.admin_note },
          ],
        },
        {
          title: '聯絡與地址',
          fields: [
            { label: 'Email', value: detail.item.contact_email },
            { label: '電話', value: detail.item.phone },
            { label: '主要地區', value: detail.item.district },
            { label: '地址 / 工作地點', value: detail.item.location },
            { label: 'Instagram', value: renderExternalLink(detail.item.instagram_url, detail.item.instagram_url) },
          ],
        },
        {
          title: '髮型師資料',
          fields: [
            { label: '名稱', value: detail.item.name },
            { label: '職銜', value: detail.item.title },
            { label: '語言', value: detail.item.languages },
            { label: '經驗', value: detail.item.experience },
            { label: '專長', value: commaList(detail.item.specialties) },
            { label: '評分', value: `${detail.item.rating} / 5 (${detail.item.reviews_count} 評論)` },
            { label: '基本價錢', value: `HK$${detail.item.base_price}` },
            { label: 'Bio', value: detail.item.bio },
          ],
        },
        {
          title: '帳號與關聯',
          fields: [
            { label: '提交帳號', value: detail.item.submitted_by },
            { label: 'Owner ID', value: detail.item.owner_id },
            { label: 'Salon ID', value: detail.item.salon_id },
            { label: '已審批者', value: detail.item.reviewed_by },
            { label: '審批時間', value: formatDateSafe(detail.item.reviewed_at) },
          ],
        },
      ];
    case 'salonApplication':
      return [
        {
          title: '審批狀態',
          fields: [
            { label: '狀態', value: statusLabel(detail.item.status) },
            { label: '提交時間', value: formatDateSafe(detail.item.created_at) },
            { label: '申請 ID', value: detail.item.id },
            { label: '沙龍 ID', value: detail.item.salon_id },
            { label: '品牌名稱', value: detail.item.brand_name },
            { label: '分店名稱', value: detail.item.branch_name },
            { label: 'Admin note', value: detail.item.admin_note },
          ],
        },
        {
          title: '沙龍資料',
          fields: [
            { label: '名稱', value: detail.item.name },
            { label: '品牌名稱', value: detail.item.brand_name },
            { label: '分店名稱', value: detail.item.branch_name },
            { label: '主要地區', value: detail.item.district },
            { label: '地址', value: detail.item.location },
            { label: '電話', value: detail.item.phone },
            { label: 'Instagram', value: renderExternalLink(detail.item.instagram_url, detail.item.instagram_url) },
            { label: '營業時間', value: detail.item.open_hours },
            { label: '起步價', value: `HK$${detail.item.start_price}` },
            { label: '標籤', value: commaList(detail.item.tags) },
            { label: '評分', value: `${detail.item.rating} / 5` },
          ],
        },
        {
          title: '帳號與審批',
          fields: [
            { label: '提交帳號', value: detail.item.submitted_by },
            { label: '已審批者', value: detail.item.reviewed_by },
            { label: '審批時間', value: formatDateSafe(detail.item.reviewed_at) },
          ],
        },
      ];
    case 'stylist':
      return [
        {
          title: '檔案資料',
          fields: [
            { label: '狀態', value: detail.item.is_active ? '上架中' : '已下架' },
            { label: '首頁推薦', value: detail.item.is_featured ? '是' : '否' },
            { label: '排序', value: detail.item.display_order },
            { label: '髮型師 ID', value: detail.item.id },
            { label: 'Owner ID', value: detail.item.owner_id },
            { label: '名稱', value: detail.item.name },
            { label: '職銜', value: detail.item.title },
            { label: '地區', value: detail.item.district },
            { label: '地址', value: detail.item.location },
            { label: '電話', value: detail.item.phone },
            { label: 'Instagram', value: renderExternalLink(detail.item.instagram_url, detail.item.instagram_url) },
            { label: '語言', value: detail.item.languages },
            { label: '經驗', value: detail.item.experience },
            { label: '評分', value: `${detail.item.rating} / 5 (${detail.item.reviews_count} 評論)` },
            { label: '基本價錢', value: `HK$${detail.item.base_price}` },
            { label: '專長', value: commaList(detail.item.specialties) },
            { label: 'Bio', value: detail.item.bio },
            { label: '建立時間', value: formatDateSafe(detail.item.created_at) },
            { label: '更新時間', value: formatDateSafe(detail.item.updated_at) },
          ],
        },
      ];
    case 'salon':
      return [
        {
          title: '檔案資料',
          fields: [
            { label: '狀態', value: detail.item.is_active ? '上架中' : '已下架' },
            { label: '首頁推薦', value: detail.item.is_featured ? '是' : '否' },
            { label: '排序', value: detail.item.display_order },
            { label: '沙龍 ID', value: detail.item.id },
            { label: '品牌 ID', value: detail.item.brand_id },
            { label: '分店名稱', value: detail.item.branch_name },
            { label: '名稱', value: detail.item.name },
            { label: '可預約', value: detail.item.booking_enabled ? '是' : '否' },
            { label: '可聊天', value: detail.item.chat_enabled ? '是' : '否' },
            { label: '地區', value: detail.item.district },
            { label: '地址', value: detail.item.location },
            { label: '電話', value: detail.item.phone },
            { label: 'Instagram', value: renderExternalLink(detail.item.instagram_url, detail.item.instagram_url) },
            { label: '營業時間', value: detail.item.open_hours },
            { label: '評分', value: `${detail.item.rating} / 5` },
            { label: '起步價', value: `HK$${detail.item.start_price}` },
            { label: '標籤', value: commaList(detail.item.tags) },
            { label: '建立時間', value: formatDateSafe(detail.item.created_at) },
            { label: '更新時間', value: formatDateSafe(detail.item.updated_at) },
          ],
        },
      ];
    case 'inspiration':
      return [
        {
          title: '靈感內容',
          fields: [
            { label: '狀態', value: detail.item.is_active ? '公開' : '已隱藏' },
            { label: '標題', value: detail.item.title },
            { label: '作者', value: detail.item.author_name },
            { label: 'Studio', value: detail.item.studio },
            { label: '標籤', value: commaList(detail.item.tags) },
            { label: '詳情', value: detail.item.details },
          ],
        },
      ];
    case 'report':
      return [
        {
          title: '檢舉資料',
          fields: [
            { label: '狀態', value: detail.item.status },
            { label: '類型', value: detail.item.entity_type },
            { label: '內容 ID', value: detail.item.entity_id },
            { label: '原因', value: detail.item.reason },
            { label: '詳情', value: detail.item.details },
            { label: '建立時間', value: formatDateSafe(detail.item.created_at) },
          ],
        },
      ];
  }
}

function detailServices(detail: DetailTarget, data: AdminData) {
  if (detail.kind === 'stylistApplication') return detail.item.services_payload ?? [];
  if (detail.kind === 'stylist') return data.services.filter((item) => item.stylist_id === detail.item.id);
  if (detail.kind === 'salonApplication') return detail.item.services_payload ?? [];
  if (detail.kind === 'salon') return data.salonServices.filter((item) => item.salon_id === detail.item.id);
  return [];
}

function detailMedia(detail: DetailTarget, data: AdminData) {
  switch (detail.kind) {
    case 'stylistApplication':
      return [
        coverMedia('頭像', detail.item.avatar_url),
        ...(detail.item.works_payload ?? []).map((item, index) => workMedia(item, index, '作品')),
      ].filter(Boolean) as DetailMediaItem[];
    case 'salonApplication':
      return [
        coverMedia('封面', detail.item.image_url),
        ...(detail.item.works_payload ?? []).map((item, index) => workMedia(item, index, '沙龍作品')),
      ].filter(Boolean) as DetailMediaItem[];
    case 'stylist':
      return [
        coverMedia('頭像', detail.item.avatar_url),
        ...data.works
          .filter((item) => item.stylist_id === detail.item.id && item.is_active !== false)
          .map((item, index) => workMedia(item, index, '作品')),
      ].filter(Boolean) as DetailMediaItem[];
    case 'salon':
      return [
        coverMedia('封面', detail.item.image_url),
        ...data.salonWorks
          .filter((item) => item.salon_id === detail.item.id && item.is_active !== false)
          .map((item, index) => workMedia(item, index, '沙龍作品')),
      ].filter(Boolean) as DetailMediaItem[];
    case 'inspiration':
      return validInspirationMediaURLs(detail.item).map((url, index) => ({
        imageURL: url,
        title: `Media ${index + 1}`,
        mediaKind: detail.item.media_kinds?.[index] === 'video' ? 'video' : 'photo',
        videoURL: detail.item.media_kinds?.[index] === 'video' ? url : undefined,
      }));
    case 'report':
      return [];
  }
}

function coverMedia(title: string, url: string | null | undefined): DetailMediaItem | null {
  const imageURL = firstUsableURL([url]);
  if (!imageURL) return null;
  return { title, imageURL, mediaKind: 'photo' };
}

function workMedia(item: PortfolioWork | SalonWork, index: number, fallbackTitle: string): DetailMediaItem | null {
  const mediaKind = item.media_kind === 'video' || isUsableRemoteMediaURL(item.video_url) ? 'video' : 'photo';
  const videoURL = mediaKind === 'video' ? firstUsableURL([item.video_url]) : '';
  const imageURL = firstUsableURL([item.thumbnail_url, item.image_url, videoURL]);
  if (!imageURL && !videoURL) return null;
  return {
    title: item.title || `${fallbackTitle} ${index + 1}`,
    imageURL,
    mediaKind,
    videoURL: videoURL || undefined,
  };
}

function firstUsableURL(values: Array<string | null | undefined>) {
  return values.map((value) => (value ?? '').trim()).find(isUsableRemoteMediaURL) ?? '';
}

function detailValue(value: ReactNode) {
  if (value === null || value === undefined || value === '') return <span className="muted-value">未填</span>;
  return value;
}

function commaList(values: string[] | null | undefined) {
  return (values ?? []).filter(Boolean).join('、');
}

function renderExternalLink(value: string | null | undefined, label: string | null | undefined) {
  const href = normalizedExternalHref(value);
  if (!href) return '';
  return (
    <a className="inline-link" href={href} target="_blank" rel="noreferrer">
      {label || href}
      <ExternalLink size={13} />
    </a>
  );
}

function normalizedExternalHref(value: string | null | undefined) {
  const clean = (value ?? '').trim();
  if (!clean) return '';
  if (clean.startsWith('@')) return `https://instagram.com/${clean.slice(1)}`;
  if (/^[a-z][a-z\d+\-.]*:\/\//i.test(clean)) return clean;
  if (/^[\w.]+$/.test(clean)) return `https://instagram.com/${clean.replace(/^@/, '')}`;
  return `https://${clean.replace(/^\/+/, '')}`;
}

const brokenMediaFragments = ['photo-1595959183075-c1d0a174db24'];

function isUsableRemoteMediaURL(value: string | null | undefined) {
  const clean = (value ?? '').trim();
  if (!clean) return false;
  if (brokenMediaFragments.some((fragment) => clean.includes(fragment))) return false;
  try {
    const url = new URL(clean);
    return url.protocol === 'http:' || url.protocol === 'https:';
  } catch {
    return false;
  }
}

function validInspirationMediaURLs(item: InspirationItem) {
  const media = [...(item.media_urls ?? []), item.image_url];
  return Array.from(new Set(media.map((url) => (url ?? '').trim()).filter(isUsableRemoteMediaURL)));
}

function hasBrokenInspirationMedia(item: InspirationItem) {
  const media = [...(item.media_urls ?? []), item.image_url].map((url) => (url ?? '').trim());
  if (!media.length || media.every((url) => !url)) return true;
  return media.some((url) => !isUsableRemoteMediaURL(url));
}

function statusLabel(status: ApplicationStatus) {
  switch (status) {
    case 'pending':
      return '待審批';
    case 'approved':
      return '已批准';
    case 'rejected':
      return '已拒絕';
    case 'hidden':
      return '已下架';
  }
}

function describeError(error: unknown) {
  if (error instanceof Error && error.message) return error.message;
  if (typeof error === 'string') return error;
  if (error && typeof error === 'object') {
    const record = error as Record<string, unknown>;
    const message = [record.message, record.details, record.hint, record.code]
      .filter((item) => typeof item === 'string' && item.trim())
      .join(' · ');
    if (message) return message;
    try {
      return JSON.stringify(error);
    } catch {
      return '發生未知錯誤，請重新整理後再試。';
    }
  }
  return '發生未知錯誤，請重新整理後再試。';
}

function formatDateSafe(value: string | null | undefined) {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return formatDate(value);
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat('zh-HK', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value));
}

function fallbackImage() {
  return 'https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=800&auto=format&fit=crop';
}
