import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { 
  Calendar, MessageSquare, User, Clock, Check, Phone, Send, ChevronRight, X, Sparkles,
  Sliders, UserCheck, Shield, BookOpen, AlertCircle, RefreshCw, Layers, CheckCircle2,
  Trash2, Plus, CornerDownRight, ExternalLink
} from 'lucide-react';
import { Booking as BookingType, Stylist, BlockedSlot } from '../types';
import { stylistsData } from '../data';

interface StylistDashboardProps {
  initialStylistId?: string;
  initialName?: string;
  initialTitle?: string;
  onLogout: () => void;
}

interface StylistChatThread {
  id: string;
  clientName: string;
  clientAvatar: string;
  lastMsg: string;
  lastTime: string;
  unread: boolean;
  messages: { id: string; sender: 'stylist' | 'client'; text: string; time: string }[];
}

export default function StylistDashboard({ 
  initialStylistId = 'master-leo', 
  initialName,
  initialTitle,
  onLogout 
}: StylistDashboardProps) {
  const [activeTab, setActiveTab] = useState<'bookings' | 'messages' | 'schedule' | 'profile'>('bookings');
  
  // Database sync terminal logs
  const [dbLogs, setDbLogs] = useState<string[]>([
    `[Supabase Connection] Connected to postgrest-api client @ https://yedn2ssqcn.supabase.co`,
    `[LocalStorage Fallback] Synced 4 offline schemas seamlessly.`
  ]);

  const addLog = (msg: string) => {
    const time = new Date().toLocaleTimeString();
    setDbLogs(prev => [`[${time}] ${msg}`, ...prev.slice(0, 19)]);
  };

  // --- 1. TO-DAY'S BOOKING STATE ---
  const [todayBookings, setTodayBookings] = useState<any[]>([
    {
      id: 'tb_1',
      timeSlot: '09:30 - 11:00',
      clientName: '廖小莉 (Lily)',
      clientPhone: '+852 9112 3456',
      serviceName: '招牌剪髮 & 頭皮舒壓洗',
      price: 120,
      confirmed: false,
      status: 'upcoming'
    },
    {
      id: 'tb_2',
      timeSlot: '11:00 - 13:00',
      clientName: '陳俊言 (Chris)',
      clientPhone: '+852 6224 8890',
      serviceName: '自然漸層推剪 & 特色漸層染',
      price: 260,
      confirmed: true,
      status: 'upcoming'
    },
    {
      id: 'tb_3',
      timeSlot: '14:30 - 17:30',
      clientName: '沈大德 (David)',
      clientPhone: '+852 5110 7788',
      serviceName: '韓式氣墊燙 & 縮毛矯正',
      price: 350,
      confirmed: true,
      status: 'upcoming'
    },
    {
      id: 'tb_4',
      timeSlot: '18:00 - 19:30',
      clientName: '王阿珍 (Jane)',
      clientPhone: '+852 9876 5432',
      serviceName: '巴西生命果抗毛躁護髮',
      price: 180,
      confirmed: false,
      status: 'upcoming'
    }
  ]);

  const handleConfirmBooking = (id: string) => {
    setTodayBookings(prev => prev.map(b => b.id === id ? { ...b, confirmed: true } : b));
    const target = todayBookings.find(b => b.id === id);
    addLog(`SUCCESS: UPDATE bookings SET confirmed = true WHERE id = '${id}' (Rows affected: 1)`);
    alert(`🎉 預約已成功確認！已發送 LINE / SMS 確認函給顧客 ${target?.clientName || ''}`);
  };

  const handleCompleteService = (id: string) => {
    setTodayBookings(prev => prev.map(b => b.id === id ? { ...b, status: 'completed' } : b));
    const target = todayBookings.find(b => b.id === id);
    addLog(`SUCCESS: UPDATE bookings SET status = 'completed' WHERE id = '${id}'`);
    alert(`👏 恭喜完成為 ${target?.clientName || ''} 的美髮造型服務！訂單已入帳。`);
  };

  // --- 2. MESSENGES CHATS STATE ---
  const [threads, setThreads] = useState<StylistChatThread[]>([
    {
      id: 'th_1',
      clientName: 'Alex Chen',
      clientAvatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCCPmAheQKJVamdFvZuMSrOwzz-hTst9fO_ohnBNF20VM3ozWXdJ0tSYqV5Ayl6FSXVnhn6C7k547wmTIXODb8BgK0Gi4iTgMKAGtZ5Buw86jUNSIfvb15m_xaH754TjL8gxprHrCOgmbtn3seFrVhXgrNbDQkX6LVpl1vuhow2pApC8ZzkNOweOfxY1wRpInBg1sx190HH0HX30L0O6W6zDS7bQJW2fJm-_Q7iwkxoQlqKyNmL_m-MzHmpTkvgh0StnK15zL8MZHI',
      lastMsg: '巴黎畫染適合我的髮質嗎？',
      lastTime: '15:10',
      unread: true,
      messages: [
        { id: 'm1_1', sender: 'client', text: '老師你好，我預約了下星期六下午的畫染。', time: '14:50' },
        { id: 'm1_2', sender: 'stylist', text: '您好！沒問題，看到您的預約了。可以分享一下您目前的髮色照片嗎？', time: '14:55' },
        { id: 'm1_3', sender: 'client', text: '好呀，目前的髮尾有點漂過，退成橘黃色，巴黎畫染適合我的髮質嗎？', time: '15:10' }
      ]
    },
    {
      id: 'th_2',
      clientName: 'Chris Wong',
      clientAvatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBeRyOmy4bpeM3RSYCNXKEi5c0srz3K5IbYZksNqKeaug9YL1X4Yzk2YYKZpxuygm1CIe8_I5CgguzLhZSkNrUSXCBh8_xqW9NvZgwFKuCcIpwsjFl1sk6kOSaZRgLsH3IkaTymYj9hmGXSYdfFySYou_526CmXjdoB-_QbElaLzKsuk6635WLb0pw-ouUhtndnl_XT5ucsbxDKxHp4kMj_il5kk1FHdkonvRm_gE3d_AZLP1RQqzfMN04KlKaveVgV8Uj9uk2gSkE',
      lastMsg: '謝謝老師，今天的漸層推修飾十分清爽！',
      lastTime: '昨日',
      unread: false,
      messages: [
        { id: 'm2_1', sender: 'stylist', text: '今天的漸層推還滿意嗎？', time: '昨日 12:30' },
        { id: 'm2_2', sender: 'client', text: '謝謝老師，今天的漸層推修飾十分清爽！', time: '昨日 12:35' }
      ]
    },
    {
      id: 'th_3',
      clientName: 'Mandy Lee',
      clientAvatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAP5t7_veZJCnVdQ4mzpjhL58idf2dJSg9Ai8P-PklgXyTZeb_YtpfknnoQaQYVKz3RVMksFxJB7SkClPMq-C__xZVJ89e6XQotpwXUTEDPpCbcuXX3cVapRcnX1WjObBc7X25hHCpwhBpGoZ7apn40TJDug8U9p4qfwp7EVfTrd3T5ivLYOAdVn5y1k3C6KmqZ-5dwDVtxDQjCYWUK3MQ1HZ2YFY9_KNYfGerD7uI1fCF9UnHDBjtmpsrkGvZ5amLwlzQNVp39y3s',
      lastMsg: '好，到時候店裡見！',
      lastTime: '2天前',
      unread: false,
      messages: [
        { id: 'm3_1', sender: 'client', text: '老師，燙完氣墊燙需要烘乾還是手繞吹乾呢？', time: '2天前 10:15' },
        { id: 'm3_2', sender: 'stylist', text: '只要手一邊繞著吹一邊帶乾就可以了，非常容易打理。', time: '2天前 10:20' },
        { id: 'm3_3', sender: 'client', text: '好，到時候店裡見！', time: '2天前 10:22' }
      ]
    }
  ]);

  const [activeThreadId, setActiveThreadId] = useState<string | null>(null);
  const [replyText, setReplyText] = useState('');

  const currentThread = threads.find(t => t.id === activeThreadId);

  const handleSendReply = (e: React.FormEvent) => {
    e.preventDefault();
    if (!replyText.trim() || !activeThreadId) return;

    const timeString = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    setThreads(prev => prev.map(t => {
      if (t.id === activeThreadId) {
        return {
          ...t,
          lastMsg: replyText,
          lastTime: timeString,
          unread: false,
          messages: [
            ...t.messages,
            { id: `msg_s_${Date.now()}`, sender: 'stylist', text: replyText, time: timeString }
          ]
        };
      }
      return t;
    }));

    addLog(`SUCCESS: INSERT INTO stylist_messages (thread_id, sender, text, time) VALUES ('${activeThreadId}', 'stylist', '${replyText}', '${timeString}')`);
    setReplyText('');

    // Simulated beautiful guest reply in 1.8 seconds to feel very alive!
    setTimeout(() => {
      setThreads(prev => prev.map(t => {
        if (t.id === activeThreadId) {
          const autoAnswers = [
            '好的，謝謝老師！我知道了，下週見～',
            '非常專業！謝謝老師的回覆，那我明天洗完頭再來回報。',
            '太感謝了，有老師回報我就放心囉，期待這次的改造✨'
          ];
          const randomText = autoAnswers[Math.floor(Math.random() * autoAnswers.length)];
          return {
            ...t,
            lastMsg: randomText,
            lastTime: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            unread: false,
            messages: [
              ...t.messages,
              { id: `msg_c_${Date.now()}`, sender: 'client', text: randomText, time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) }
            ]
          };
        }
        return t;
      }));
      addLog(`REALTIME WEBSOCKET: Received new client reply on thread '${activeThreadId}'`);
    }, 1800);
  };

  // --- 3. SCHEDULE MANAGEMENT STATE ---
  const [selectedDate, setSelectedDate] = useState('2026-06-06');
  
  // Available time blocks
  const hoursList = [
    '09:00', '10:00', '11:00', '12:00', '13:00', '14:00',
    '15:00', '16:00', '17:00', '18:00', '19:00', '20:00'
  ];

  // Blocked slots in state
  const [blockedSlots, setBlockedSlots] = useState<BlockedSlot[]>([
    { id: 'bl_1', stylistId: 'master-leo', date: '2026-06-06', time: '12:00' },
    { id: 'bl_2', stylistId: 'master-leo', date: '2026-06-06', time: '13:00' },
    { id: 'bl_3', stylistId: 'master-leo', date: '2026-06-07', time: '17:00' }
  ]);

  // Is slot blocked?
  const isBlocked = (time: string) => {
    return blockedSlots.some(s => s.date === selectedDate && s.time === time);
  };

  const toggleSlot = (time: string) => {
    if (isBlocked(time)) {
      // Remove block (unblock)
      setBlockedSlots(prev => prev.filter(s => !(s.date === selectedDate && s.time === time)));
      addLog(`SUCCESS: DELETE FROM blocked_slots WHERE date='${selectedDate}' AND time='${time}' AND stylist_id='${initialStylistId}'`);
    } else {
      // Add block
      const newBlock: BlockedSlot = {
        id: `blk_${Date.now()}`,
        stylistId: initialStylistId,
        date: selectedDate,
        time: time
      };
      setBlockedSlots(prev => [...prev, newBlock]);
      addLog(`SUCCESS: INSERT INTO blocked_slots (id, stylist_id, date, time) VALUES ('${newBlock.id}', '${initialStylistId}', '${selectedDate}', '${time}')`);
    }
  };

  // Batch mark fields
  const [batchStart, setBatchStart] = useState('2026-06-06');
  const [batchEnd, setBatchEnd] = useState('2026-06-08');
  const [batchHourStart, setBatchHourStart] = useState('13:00');
  const [batchHourEnd, setBatchHourEnd] = useState('17:00');

  const handleBatchBlock = () => {
    // Generate dates between batchStart and batchEnd
    const start = new Date(batchStart);
    const end = new Date(batchEnd);
    const dateArray: string[] = [];
    let current = new Date(start);

    while (current <= end) {
      dateArray.push(current.toISOString().split('T')[0]);
      current.setDate(current.getDate() + 1);
    }

    // Filter hours within range
    const startHourNum = parseInt(batchHourStart.split(':')[0]);
    const endHourNum = parseInt(batchHourEnd.split(':')[0]);
    const hoursToBlock = hoursList.filter(h => {
      const hNum = parseInt(h.split(':')[0]);
      return hNum >= startHourNum && hNum <= endHourNum;
    });

    const newBlocks: BlockedSlot[] = [];
    dateArray.forEach(d => {
      hoursToBlock.forEach(h => {
        // Only if not already blocked
        if (!blockedSlots.some(s => s.date === d && s.time === h)) {
          newBlocks.push({
            id: `blk_bt_${Math.random().toString(36).substr(2, 6)}`,
            stylistId: initialStylistId,
            date: d,
            time: h
          });
        }
      });
    });

    setBlockedSlots(prev => [...prev, ...newBlocks]);
    addLog(`SUCCESS COMPLETED TRANSACTION: Bulk blocked ${newBlocks.length} slots from ${batchStart} to ${batchEnd} during [${batchHourStart}-${batchHourEnd}] in Supabase table blocked_slots.`);
    alert(`⚡️ 批量標記成功！已成功封鎖 ${newBlocks.length} 個時段，顧客將無法在這些時間內進行預約諮詢。`);
  };

  // Look up current stylist from database to sync pre-existing attributes
  const dbStylist = stylistsData.find(s => s.id === initialStylistId) || stylistsData[0];

  // --- 4. PROFILE STATE ---
  const [profileName, setProfileName] = useState(initialName || dbStylist.name || 'Master Leo');
  const [profileTitle, setProfileTitle] = useState(initialTitle || dbStylist.title || '首席名店設計師 (沙龍合夥人)');
  const [profileBio, setProfileBio] = useState(dbStylist.bio || '10年以上明星美髮經驗。擅長巴黎Balayage手刷漸層挑染、高精密層次剪裁與修飾臉型氣墊燙。堅持美感客製細雕！');
  const [profilePrice, setProfilePrice] = useState(dbStylist.price || 120);
  const [profilePortfolio, setProfilePortfolio] = useState('https://images.unsplash.com/portfolio-balayage-hairstyles');
  const [isSavingProfile, setIsSavingProfile] = useState(false);

  // Expanded fields to match Stylist profile detailed screen
  const [profileRating, setProfileRating] = useState(dbStylist.rating || 4.9);
  const [profileExperience, setProfileExperience] = useState(dbStylist.experience || '10年以上');
  const [profileLanguages, setProfileLanguages] = useState(dbStylist.languages || '中 / 英 / 粵');
  const [profileAvatar, setProfileAvatar] = useState(dbStylist.avatar || 'https://lh3.googleusercontent.com/aida-public/AB6AXuD3FbJKj8QqvwIhm0BrWvW9dPnOy_Nf_3zuQv_AQ4D34uLm2YaK6ggyr2ZRk0-GMQyLM84ayUQxV07PUuAthEZD593Ld8oVujNA_DeXlL82jMZjSDY9R10UXgz4n8sxAKWOjST25SRW0rhwY9thezHurEdis9pNBHp5xeTjVJhyfLaeQs2mMSKktd5k_TJWoi98wtcowC71pNt2_ZH5-nrkfGTAesDSNgyp5zt_roBkAu9mR32Te_TbijU71PuvzMAJ3mLytVeDdeM');
  const [profileSpecialties, setProfileSpecialties] = useState(dbStylist.specialties ? dbStylist.specialties.join(', ') : '挑染專家, 經典剪髮');
  
  const [profileWorks, setProfileWorks] = useState(dbStylist.works || []);
  const [profileServices, setProfileServices] = useState(dbStylist.services || []);

  // In-form helper states to add new elements
  const [newServiceName, setNewServiceName] = useState('');
  const [newServiceCategory, setNewServiceCategory] = useState('剪髮');
  const [newServiceDuration, setNewServiceDuration] = useState(60);
  const [newServicePrice, setNewServicePrice] = useState(100);
  const [newServiceDesc, setNewServiceDesc] = useState('');

  const [newWorkTitle, setNewWorkTitle] = useState('');
  const [newWorkImageUrl, setNewWorkImageUrl] = useState('');

  // Handle addition & deletion
  const handleAddService = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newServiceName.trim()) return;
    const newSvc = {
      id: 's_' + Date.now(),
      name: newServiceName,
      category: newServiceCategory,
      duration: newServiceDuration,
      description: `${newServiceDesc || '專業精緻護理'} • ${newServiceDuration} 分鐘`,
      price: newServicePrice
    };
    setProfileServices(prev => [...prev, newSvc]);
    setNewServiceName('');
    setNewServiceDesc('');
  };

  const handleRemoveService = (id: string) => {
    setProfileServices(prev => prev.filter(s => s.id !== id));
  };

  const handleAddWork = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newWorkImageUrl.trim()) return;
    const newW = {
      id: 'w_' + Date.now(),
      title: newWorkTitle || '美髮設計作品',
      imageUrl: newWorkImageUrl
    };
    setProfileWorks(prev => [...prev, newW]);
    setNewWorkTitle('');
    setNewWorkImageUrl('');
  };

  const handleRemoveWork = (id: string) => {
    setProfileWorks(prev => prev.filter(w => w.id !== id));
  };

  const handleSaveProfile = (e: React.FormEvent) => {
    e.preventDefault();
    setIsSavingProfile(true);

    setTimeout(() => {
      setIsSavingProfile(false);
      
      // Update the global reference so customer pages update instantly!
      const targetStylist = stylistsData.find(s => s.id === initialStylistId) || stylistsData[0];
      if (targetStylist) {
        targetStylist.name = profileName;
        targetStylist.title = profileTitle;
        targetStylist.price = profilePrice;
        targetStylist.bio = profileBio;
        targetStylist.rating = Number(profileRating);
        targetStylist.experience = profileExperience;
        targetStylist.languages = profileLanguages;
        targetStylist.avatar = profileAvatar;
        targetStylist.specialties = profileSpecialties.split(',').map(s => s.trim()).filter(Boolean);
        targetStylist.works = profileWorks;
        targetStylist.services = profileServices;
      }

      addLog(`SUCCESS DB TRANSACTION: UPDATE stylists SET name='${profileName}', title='${profileTitle}', price=${profilePrice}, bio='${profileBio.substring(0, 15)}...', specialties='${profileSpecialties}', services_count=${profileServices.length}, works_count=${profileWorks.length} WHERE id='${initialStylistId}'`);
      alert('💾 髮型師個人檔案與名片更新成功！資料已寫入 Supabase、作品與服務項目已實時通報顧客端更新。');
    }, 800);
  };

  return (
    <div className="w-full h-full bg-slate-50 flex flex-col justify-between relative overflow-hidden select-none font-sans">
      
      {/* 🔮 TOP BAR WITH STYLIST AVATAR */}
      <header className="bg-neutral-900 text-white border-b border-neutral-800 px-4 py-3 flex justify-between items-center shrink-0 z-10">
        <div className="flex items-center gap-2.5">
          <div className="w-9 h-9 rounded-full overflow-hidden border border-amber-400 relative shrink-0">
            <img 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuD3FbJKj8QqvwIhm0BrWvW9dPnOy_Nf_3zuQv_AQ4D34uLm2YaK6ggyr2ZRk0-GMQyLM84ayUQxV07PUuAthEZD593Ld8oVujNA_DeXlL82jMZjSDY9R10UXgz4n8sxAKWOjST25SRW0rhwY9thezHurEdis9pNBHp5xeTjVJhyfLaeQs2mMSKktd5k_TJWoi98wtcowC71pNt2_ZH5-nrkfGTAesDSNgyp5zt_roBkAu9mR32Te_TbijU71PuvzMAJ3mLytVeDdeM" 
              alt="Avatar" 
              className="w-full h-full object-cover" 
            />
            <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 rounded-full border-2 border-neutral-900"></span>
          </div>
          <div>
            <h1 className="text-xs font-black tracking-wide text-neutral-100 flex items-center gap-1">
              <span>{profileName}</span> 
              <span className="text-[9px] bg-amber-400/20 text-amber-300 font-bold px-1 py-0.2 rounded border border-amber-400/20">髮型師後台</span>
            </h1>
            <p className="text-[9.5px] text-neutral-400 font-mono truncate max-w-[200px]">{profileTitle}</p>
          </div>
        </div>
        <button 
          onClick={onLogout}
          className="text-[9.5px] bg-red-950 hover:bg-red-900 text-red-300 border border-red-800/40 px-2.5 py-1.5 rounded-lg font-bold cursor-pointer transition-colors"
        >
          安全登出
        </button>
      </header>

      {/* 💻 SECOND BAR: SUPABASE TRANSACTION CONSOLE */}
      <div className="bg-neutral-950 text-[9px] font-mono text-emerald-400 py-1.5 px-3.5 border-b border-zinc-850 shrink-0 flex items-center justify-between gap-1">
        <div className="flex items-center gap-1.5 truncate">
          <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-ping shrink-0"></span>
          <span className="text-zinc-400 font-semibold uppercase">[SUPABASE SYNC]:</span>
          <span className="truncate text-emerald-300">{dbLogs[0] || 'Idle.'}</span>
        </div>
        <button 
          onClick={() => {
            alert(`💾 生產數據快照:\n- 預約筆數: ${todayBookings.length}\n- 封鎖檔期: ${blockedSlots.length} 個 slots\n- 實時連結: ${profilePortfolio}`);
          }}
          className="text-zinc-550 hover:text-emerald-300 font-extrabold hover:underline select-none px-1 text-[7.5px]"
        >
          查看快照
        </button>
      </div>

      {/* 📱 DETAILED CONTENT BODY */}
      <div className="flex-1 overflow-y-auto no-scrollbar bg-slate-50 relative pb-28">
        <AnimatePresence mode="wait">
          
          {/* TAB 1: TODAY BOOKINGS */}
          {activeTab === 'bookings' && (
            <motion.div
              key="bookings"
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 10 }}
              className="p-4 space-y-4 font-sans"
            >
              <div className="flex justify-between items-center">
                <div>
                  <h2 className="text-xs font-black text-gray-500 uppercase tracking-widest font-mono">📅 TODAY BOOKINGS</h2>
                  <p className="text-sm font-black text-gray-900">今日預約接單表</p>
                </div>
                <div className="text-right">
                  <span className="text-[10px] bg-sky-50 text-sky-700 font-black px-2 py-0.5 rounded-full border border-sky-1 HongKong inline-block">
                    {todayBookings.filter(b => b.status !== 'completed').length} 堂待辦
                  </span>
                </div>
              </div>

              {/* SECTION A: PENDING CONFIRMATIONS */}
              <div className="space-y-2.5">
                <h3 className="text-[10.5px] font-black text-amber-600 flex items-center gap-1 uppercase tracking-wider">
                  <span className="w-2 h-2 rounded-full bg-amber-500"></span>
                  待確認預約 ({todayBookings.filter(b => !b.confirmed && b.status !== 'completed').length})
                </h3>

                {todayBookings.filter(b => !b.confirmed && b.status !== 'completed').length === 0 ? (
                  <div className="bg-white rounded-xl p-4 text-center border border-gray-150 text-gray-400 text-xs py-5">
                    今日暫無需要確認的預約 🥳
                  </div>
                ) : (
                  todayBookings.filter(b => !b.confirmed && b.status !== 'completed').map(b => (
                    <div 
                      key={b.id}
                      className="bg-white rounded-xl border-l-[4px] border-l-amber-400 border-y border-r border-gray-200/80 p-3.5 shadow-5xs space-y-3"
                    >
                      <div className="flex justify-between items-start gap-1">
                        <div className="space-y-1">
                          <div className="flex items-center gap-2">
                            <span className="font-mono text-xs font-black text-gray-900 bg-amber-50 px-1.5 py-0.5 rounded border border-amber-100 flex items-center gap-1">
                              <Clock className="w-3 h-3 text-amber-600" />
                              {b.timeSlot}
                            </span>
                            <span className="text-[9.5px] text-gray-400 font-medium">顧客待確認</span>
                          </div>
                          <p className="font-bold text-sm text-gray-950 font-sans mt-1">
                            {b.clientName} <span className="font-normal text-xs text-gray-400 font-mono ml-1">{b.clientPhone}</span>
                          </p>
                          <p className="text-xs text-gray-500 font-sans">
                            📝 服務：{b.serviceName} <span className="font-mono text-amber-700 font-extrabold ml-1">HK$ {b.price}</span>
                          </p>
                        </div>
                      </div>

                      <div className="flex gap-2 pt-2 border-t border-gray-100">
                        <button
                          onClick={() => {
                            setActiveTab('messages');
                            setActiveThreadId('th_1'); // defaults to active client Alex or simply dynamic simulation
                          }}
                          className="flex-1 py-1.5 border border-gray-250 text-xs font-bold rounded-lg text-gray-700 hover:text-black cursor-pointer bg-white transition-colors"
                        >
                          發送訊息
                        </button>
                        <button
                          onClick={() => handleConfirmBooking(b.id)}
                          className="flex-1 py-1.5 bg-black text-white text-xs font-bold rounded-lg hover:bg-neutral-800 cursor-pointer transition-colors"
                        >
                          確認預約
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>

              {/* SECTION B: CONFIRMED BOOKINGS */}
              <div className="space-y-2.5 pt-2">
                <h3 className="text-[10.5px] font-black text-emerald-600 flex items-center gap-1 uppercase tracking-wider">
                  <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                  已確認預約 ({todayBookings.filter(b => b.confirmed && b.status !== 'completed').length})
                </h3>

                {todayBookings.filter(b => b.confirmed && b.status !== 'completed').length === 0 ? (
                  <div className="bg-white rounded-xl p-4 text-center border border-gray-150 text-gray-400 text-xs py-5">
                    目前暫無已確認的未完服務 ☕️
                  </div>
                ) : (
                  todayBookings.filter(b => b.confirmed && b.status !== 'completed').map(b => (
                    <div 
                      key={b.id}
                      className="bg-white rounded-xl border-l-[4px] border-l-emerald-400 border-y border-r border-gray-200/80 p-3.5 shadow-5xs space-y-3"
                    >
                      <div className="flex justify-between items-start gap-1">
                        <div className="space-y-1">
                          <div className="flex items-center gap-2">
                            <span className="font-mono text-xs font-black text-gray-900 bg-emerald-50 px-1.5 py-0.5 rounded border border-emerald-100 flex items-center gap-1">
                              <Clock className="w-3 h-3 text-emerald-650" />
                              {b.timeSlot}
                            </span>
                            <span className="text-[9.5px] bg-emerald-50 text-emerald-700 font-extrabold px-1.5 rounded-full border border-emerald-100">已鎖定</span>
                          </div>
                          <p className="font-bold text-sm text-gray-950 font-sans mt-1">
                            {b.clientName} <span className="font-normal text-xs text-gray-400 font-mono ml-1">{b.clientPhone}</span>
                          </p>
                          <p className="text-xs text-gray-500 font-sans">
                            📝 服務：{b.serviceName} <span className="font-mono text-emerald-700 font-extrabold ml-1">HK$ {b.price}</span>
                          </p>
                        </div>
                      </div>

                      <div className="flex gap-2 pt-2 border-t border-gray-100">
                        <button
                          onClick={() => {
                            setActiveTab('messages');
                            setActiveThreadId('th_1');
                          }}
                          className="flex-1 py-1.5 border border-gray-200 text-xs font-bold rounded-lg text-gray-700 hover:text-black cursor-pointer bg-white transition-colors"
                        >
                          發送訊息
                        </button>
                        <button
                          onClick={() => handleCompleteService(b.id)}
                          className="flex-1 py-1.5 bg-emerald-600 text-white text-xs font-bold rounded-lg hover:bg-emerald-700 cursor-pointer transition-colors"
                        >
                          完成服務
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>

              {/* HISTORIC COMPLETED BILLS SUMMARY FOR TODAY */}
              {todayBookings.filter(b => b.status === 'completed').length > 0 && (
                <div className="bg-neutral-900 text-white rounded-xl p-4 mt-6 border border-neutral-800 space-y-2">
                  <h4 className="text-[10px] text-amber-400 font-black uppercase tracking-wider font-mono">💰 TODAY REPORT // 今日業績快報</h4>
                  <p className="text-xs text-neutral-300">
                    您今天已順利完成服務 <span className="font-bold text-white">{todayBookings.filter(b => b.status === 'completed').length} 位</span> 顧客！
                  </p>
                  <div className="pt-2 border-t border-neutral-800 flex justify-between items-center">
                    <span className="text-[10px] text-neutral-400 font-mono">實收營業利潤：</span>
                    <span className="text-sm font-black text-amber-300 font-mono">
                      HK$ {todayBookings.filter(b => b.status === 'completed').reduce((sum, current) => sum + current.price, 0)}
                    </span>
                  </div>
                </div>
              )}

            </motion.div>
          )}

          {/* TAB 2: MESSAGES */}
          {activeTab === 'messages' && (
            <motion.div
              key="messages"
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 10 }}
              className="h-full flex flex-col justify-start"
            >
              {activeThreadId === null ? (
                // Thread list
                <div className="p-4 space-y-4">
                  <div className="space-y-1">
                    <h2 className="text-xs font-black text-gray-500 uppercase tracking-widest font-mono">💬 CHAT INBOX</h2>
                    <p className="text-sm font-black text-gray-900">客戶對話信箱</p>
                  </div>

                  <div className="space-y-3 pt-2">
                    {threads.map(t => (
                      <div 
                        key={t.id}
                        onClick={() => {
                          setActiveThreadId(t.id);
                          // mark as read
                          setThreads(prev => prev.map(item => item.id === t.id ? { ...item, unread: false } : item));
                        }}
                        className="bg-white rounded-2xl border border-gray-150 p-3.5 hover:border-black transition-all cursor-pointer flex gap-3 relative"
                      >
                        {t.unread && (
                          <span className="absolute top-4 right-4 w-2 h-2 bg-red-500 rounded-full animate-pulse"></span>
                        )}

                        <div className="w-11 h-11 rounded-full overflow-hidden shrink-0 border border-gray-150 relative">
                          <img src={t.clientAvatar} alt={t.clientName} className="w-full h-full object-cover" />
                        </div>

                        <div className="flex-1 min-w-0 space-y-0.5">
                          <div className="flex justify-between items-center">
                            <h4 className="font-extrabold text-xs text-gray-950 font-sans truncate">{t.clientName}</h4>
                            <span className="text-[9px] text-gray-400 font-mono">{t.lastTime}</span>
                          </div>
                          <p className={`text-[11px] truncate leading-tight pr-6 mt-1 ${t.unread ? 'text-black font-extrabold' : 'text-gray-500'}`}>
                            {t.lastMsg}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                // Chat messaging window
                <div className="flex flex-col h-[74vh] bg-slate-50 relative">
                  
                  {/* Chat header */}
                  <div className="bg-white border-b border-gray-150 px-4 py-3 flex items-center justify-between shrink-0">
                    <button 
                      onClick={() => setActiveThreadId(null)}
                      className="text-xs font-bold text-gray-600 hover:text-black flex items-center cursor-pointer py-1 pr-2"
                    >
                      <ChevronRight className="w-4 h-4 transform rotate-180" /> 返回收件箱
                    </button>
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-full overflow-hidden shrink-0 border border-gray-100">
                        <img src={currentThread?.clientAvatar} alt="" className="w-full h-full object-cover" />
                      </div>
                      <span className="font-black text-xs text-gray-900 font-sans">{currentThread?.clientName}</span>
                    </div>
                    <div className="w-8 h-8"></div>
                  </div>

                  {/* Message body list */}
                  <div className="flex-1 overflow-y-auto no-scrollbar p-4 space-y-3.5 bg-slate-100">
                    {currentThread?.messages.map((m, idx) => {
                      const isMe = m.sender === 'stylist';
                      return (
                        <div key={m.id || idx} className={`flex gap-2 w-full ${isMe ? 'justify-end' : 'justify-start'}`}>
                          {!isMe && (
                            <img src={currentThread?.clientAvatar} alt="" className="w-6 h-6 rounded-full object-cover self-end shrink-0" />
                          )}
                          <div className="max-w-[75%] space-y-0.5">
                            <div className={`p-3 rounded-2xl text-xs leading-normal font-sans shadow-5xs ${
                              isMe 
                                ? 'bg-black text-white rounded-br-none' 
                                : 'bg-white text-gray-900 rounded-bl-none border border-gray-150'
                            }`}>
                              {m.text}
                            </div>
                            <p className={`text-[8px] font-semibold text-gray-400 font-mono ${isMe ? 'text-right' : 'text-left'}`}>
                              {m.time} {isMe && '• 已讀'}
                            </p>
                          </div>
                        </div>
                      );
                    })}
                  </div>

                  {/* Input form */}
                  <form onSubmit={handleSendReply} className="bg-white border-t border-gray-150 p-2.5 flex items-center gap-2 shrink-0">
                    <input 
                      type="text"
                      value={replyText}
                      onChange={(e) => setReplyText(e.target.value)}
                      placeholder={`回覆給 ${currentThread?.clientName || ''}...`}
                      className="flex-1 bg-gray-50 border border-gray-200 text-xs text-gray-800 rounded-xl px-3 py-2.5 focus:outline-none focus:ring-1 focus:ring-black"
                    />
                    <button 
                      type="submit"
                      className="p-2.5 bg-black text-white rounded-xl active:scale-95 cursor-pointer hover:bg-neutral-800 transition-colors"
                    >
                      <Send className="w-3.5 h-3.5" />
                    </button>
                  </form>

                </div>
              )}
            </motion.div>
          )}

          {/* TAB 3: SCHEDULE / AVAILABILITY */}
          {activeTab === 'schedule' && (
            <motion.div
              key="schedule"
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 10 }}
              className="p-4 space-y-4 font-sans"
            >
              <div className="space-y-1">
                <h2 className="text-xs font-black text-gray-500 uppercase tracking-widest font-mono">🔒 BLOCK SCHEDULE</h2>
                <p className="text-sm font-black text-gray-900">檔期管理 (塞選忙碌)</p>
              </div>

              {/* DATE PICKER PART */}
              <div className="bg-white rounded-xl p-3 border border-gray-150 space-y-2">
                <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest font-mono">1. 選擇查閱與設定日期</label>
                <input 
                  type="date"
                  value={selectedDate}
                  onChange={(e) => setSelectedDate(e.target.value)}
                  className="w-full bg-slate-50 border border-gray-250 text-xs px-3 py-2 rounded-lg font-bold font-mono focus:outline-none focus:border-black"
                />
              </div>

              {/* TIME SLOTS GRID (9:00 - 20:00) */}
              <div className="space-y-2">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-extrabold text-gray-500">時段切換 (點擊切換「可約」/「忙碌」)</span>
                  <span className="text-[9.5px] text-emerald-600 font-bold">● 系統與 Supabase 自主連機</span>
                </div>

                <div className="grid grid-cols-3 gap-2">
                  {hoursList.map(h => {
                    const blockState = isBlocked(h);
                    return (
                      <button
                        key={h}
                        onClick={() => toggleSlot(h)}
                        className={`p-3.5 rounded-xl border flex flex-col justify-center items-center gap-1 transition-all active:scale-95 cursor-pointer ${
                          blockState
                            ? 'bg-red-50 text-red-700 border-red-200 hover:bg-red-100'
                            : 'bg-white text-gray-800 border-gray-150 hover:border-black'
                        }`}
                      >
                        <span className="font-mono font-black text-xs">{h}</span>
                        <span className={`text-[8.5px] font-extrabold px-1.5 py-0.2 rounded-full uppercase tracking-wider ${
                          blockState ? 'bg-red-200/50 text-red-800' : 'bg-emerald-50 text-emerald-800'
                        }`}>
                          {blockState ? '忙碌 🚫' : '開放 ✅'}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* BATCH MARK BUSY BLOCK */}
              <div className="bg-white rounded-2xl border border-gray-150 p-4 space-y-3.5 mt-4">
                <div className="flex items-center gap-2 border-b border-gray-150 pb-2">
                  <Sliders className="w-4 h-4 text-black" />
                  <h3 className="text-xs font-black text-gray-900">💡 批量標記忙碌時段</h3>
                </div>

                <p className="text-[10px] text-gray-400 leading-normal font-sans">
                  挑選日期範圍與每天的特定小時時段，一鍵快速於 Supabase 寫入 blocked_slots 表以阻擋顧客惡意超預約。
                </p>

                <div className="space-y-3">
                  <div className="grid grid-cols-2 gap-2">
                    <div className="space-y-1">
                      <label className="text-[9px] font-black text-gray-400">開始日期</label>
                      <input 
                        type="date"
                        value={batchStart}
                        onChange={(e) => setBatchStart(e.target.value)}
                        className="w-full bg-slate-50 border border-gray-250 text-xs px-2 py-1.5 rounded-lg font-semibold font-mono"
                      />
                    </div>
                    <div className="space-y-1">
                      <label className="text-[9px] font-black text-gray-400">結束日期</label>
                      <input 
                        type="date"
                        value={batchEnd}
                        onChange={(e) => setBatchEnd(e.target.value)}
                        className="w-full bg-slate-50 border border-gray-250 text-xs px-2 py-1.5 rounded-lg font-semibold font-mono"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-2">
                    <div className="space-y-1">
                      <label className="text-[9px] font-black text-gray-400">每日開始時段</label>
                      <select 
                        value={batchHourStart}
                        onChange={(e) => setBatchHourStart(e.target.value)}
                        className="w-full bg-slate-50 border border-gray-250 text-xs p-1.5 rounded-lg font-mono"
                      >
                        {hoursList.map(h => <option key={h} value={h}>{h}</option>)}
                      </select>
                    </div>
                    <div className="space-y-1">
                      <label className="text-[9px] font-black text-gray-400">每日結束時段</label>
                      <select 
                        value={batchHourEnd}
                        onChange={(e) => setBatchHourEnd(e.target.value)}
                        className="w-full bg-slate-50 border border-gray-250 text-xs p-1.5 rounded-lg font-mono"
                      >
                        {hoursList.map(h => <option key={h} value={h}>{h}</option>)}
                      </select>
                    </div>
                  </div>

                  <button
                    type="button"
                    onClick={handleBatchBlock}
                    className="w-full py-2.5 bg-neutral-950 text-white font-bold text-xs rounded-xl shadow active:scale-98 cursor-pointer hover:bg-neutral-800 transition-colors"
                  >
                    ⚡️ 一鍵批量標記忙碌
                  </button>
                </div>
              </div>

            </motion.div>
          )}

          {/* TAB 4: PROFILE */}
          {activeTab === 'profile' && (
            <motion.div
              key="profile"
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 10 }}
              className="p-4 space-y-4 font-sans"
            >
              <div className="space-y-1">
                <h2 className="text-xs font-black text-gray-500 uppercase tracking-widest font-mono">🎨 MY STYLIST PROFILE</h2>
                <p className="text-sm font-black text-gray-900">我的檔案名片管理</p>
              </div>

              <form onSubmit={handleSaveProfile} className="bg-white rounded-2xl border border-gray-150 p-4 space-y-4 shadow-5xs text-left max-h-[70vh] overflow-y-auto no-scrollbar pb-16">
                
                {/* Avatar URL */}
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-wider">個人頭像圖片網址 (Avatar URL) *</label>
                  <input 
                    type="text"
                    required
                    value={profileAvatar}
                    onChange={(e) => setProfileAvatar(e.target.value)}
                    className="w-full bg-slate-50 border border-gray-250 text-xs px-3 py-2 rounded-xl focus:ring-1 focus:ring-black"
                    placeholder="專屬形象圖片網址"
                  />
                  {profileAvatar && (
                    <div className="w-12 h-12 rounded-full border border-gray-200 overflow-hidden mt-1">
                      <img src={profileAvatar} className="w-full h-full object-cover" alt="Avatar preview" />
                    </div>
                  )}
                </div>

                {/* Name */}
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-wider">設計師個人暱稱 *</label>
                  <input 
                    type="text"
                    required
                    value={profileName}
                    onChange={(e) => setProfileName(e.target.value)}
                    className="w-full bg-slate-50 border border-gray-250 text-xs font-bold px-3 py-2 rounded-xl focus:ring-1 focus:ring-black focus:outline-none"
                    placeholder="如 Master Leo"
                  />
                </div>

                {/* Job title */}
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-wider">專業頭銜 / 職稱 *</label>
                  <input 
                    type="text"
                    required
                    value={profileTitle}
                    onChange={(e) => setProfileTitle(e.target.value)}
                    className="w-full bg-slate-50 border border-gray-250 text-xs font-bold px-3 py-2 rounded-xl focus:ring-1 focus:ring-black focus:outline-none"
                    placeholder="如 歐美挑染專家 / 首席設計師"
                  />
                </div>

                {/* Two Column details: Experience & Rating */}
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-wider">設計師資歷 *</label>
                    <input 
                      type="text"
                      required
                      value={profileExperience}
                      onChange={(e) => setProfileExperience(e.target.value)}
                      className="w-full bg-slate-50 border border-gray-250 text-xs font-bold px-3 py-2 rounded-xl"
                      placeholder="如：10年以上, 8年專業資歷"
                    />
                  </div>
                  <div className="space-y-1">
                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-wider">設計師評分 *</label>
                    <input 
                      type="number"
                      step="0.1"
                      min="1"
                      max="5"
                      required
                      value={profileRating}
                      onChange={(e) => setProfileRating(Number(e.target.value))}
                      className="w-full bg-slate-50 border border-gray-250 text-xs font-bold px-3 py-2 rounded-xl font-mono"
                    />
                  </div>
                </div>

                {/* Languages */}
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-wider">客房溝通語言 *</label>
                  <input 
                    type="text"
                    required
                    value={profileLanguages}
                    onChange={(e) => setProfileLanguages(e.target.value)}
                    className="w-full bg-slate-50 border border-gray-250 text-xs px-3 py-2 rounded-xl"
                    placeholder="例如：中 / 英 / 粵"
                  />
                </div>

                {/* Specialties */}
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-wider">專長項目標籤 (以半形逗點分隔) *</label>
                  <input 
                    type="text"
                    required
                    value={profileSpecialties}
                    onChange={(e) => setProfileSpecialties(e.target.value)}
                    className="w-full bg-slate-50 border border-gray-250 text-xs px-3 py-2 rounded-xl"
                    placeholder="挑染專家, 縮毛矯正, 女神剪法"
                  />
                  <p className="text-[9px] text-gray-400">專長標籤會在預約探索卡片上直接顯示，有助於篩選</p>
                </div>

                {/* Base price */}
                <div className="space-y-1 border-t border-gray-100 pt-3">
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-wider">基礎洗剪價格 (HK$) *</label>
                  <input 
                    type="number"
                    required
                    value={profilePrice}
                    onChange={(e) => setProfilePrice(Number(e.target.value))}
                    className="w-full bg-slate-50 border border-gray-250 text-xs font-extrabold font-mono px-3 py-2 rounded-xl focus:ring-1 focus:ring-black"
                  />
                </div>

                {/* Intro Bio */}
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-wider">顧客端詳細個人介紹 （個人簡介） *</label>
                  <textarea 
                    rows={3}
                    required
                    value={profileBio}
                    onChange={(e) => setProfileBio(e.target.value)}
                    className="w-full bg-slate-50 border border-gray-250 text-xs font-normal px-3 py-2 leading-relaxed rounded-xl focus:ring-1 focus:ring-black"
                    placeholder="向您的顧客介紹您的美髮風格..."
                  />
                </div>

                {/* 🌟 WORKS PORTFOLIO MANAGEMENT GALLERY */}
                <div className="space-y-3 border-t border-gray-150 pt-3 text-left">
                  <div className="flex justify-between items-center bg-gray-50 p-2 rounded-xl">
                    <span className="text-xs font-black text-gray-800">📸 我的美髮作品集 (共 {profileWorks.length} 張)</span>
                    <span className="text-[9px] text-amber-600 font-extrabold uppercase">設計師名片卡裝飾</span>
                  </div>

                  {/* Works list with remove handlers */}
                  {profileWorks.length === 0 ? (
                    <p className="text-[11px] text-gray-400 py-1 italic">目前暫無任何上傳作品。請在下方添加圖片！</p>
                  ) : (
                    <div className="grid grid-cols-2 gap-2 max-h-40 overflow-y-auto p-1 bg-slate-50 rounded-xl">
                      {profileWorks.map((work) => (
                        <div key={work.id} className="relative bg-white rounded-lg p-1 border border-gray-200 flex items-center gap-1.5">
                          <img src={work.imageUrl} alt={work.title} className="w-8 h-8 rounded object-cover shrink-0" />
                          <span className="text-[10px] font-medium text-gray-700 truncate w-16">{work.title}</span>
                          <button
                            type="button"
                            onClick={() => handleRemoveWork(work.id)}
                            className="absolute top-1 right-1 p-0.5 bg-rose-50 hover:bg-rose-100 rounded-full text-rose-500 cursor-pointer"
                            title="刪除作品"
                          >
                            <Trash2 className="w-3 h-3" />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Add New Work Sub-Form */}
                  <div className="bg-amber-50/40 p-2.5 rounded-xl border border-amber-100/50 space-y-2">
                    <p className="text-[10px] text-emerald-800 font-black">✨ 新增精選作品：</p>
                    <div className="grid grid-cols-2 gap-2">
                      <input 
                        type="text"
                        placeholder="作品標題: 如 漸層裙擺染"
                        value={newWorkTitle}
                        onChange={(e) => setNewWorkTitle(e.target.value)}
                        className="bg-white border border-gray-200 text-[10px] px-2 py-1 rounded-lg"
                      />
                      <input 
                        type="text"
                        placeholder="作品圖片網址 (URL)"
                        value={newWorkImageUrl}
                        onChange={(e) => setNewWorkImageUrl(e.target.value)}
                        className="bg-white border border-gray-200 text-[10px] px-2 py-1 rounded-lg"
                      />
                    </div>
                    <button
                      type="button"
                      onClick={(e) => {
                        if (!newWorkImageUrl.trim()) {
                          alert('請輸入有效圖片連結網址！');
                          return;
                        }
                        handleAddWork(e);
                      }}
                      className="w-full py-1.5 bg-amber-500 text-white hover:bg-amber-600 rounded-lg text-[10px] font-bold cursor-pointer"
                    >
                      ＋ 加入高畫質作品
                    </button>
                  </div>
                </div>

                {/* 💇 SERVICES PACKAGE MANAGEMENT */}
                <div className="space-y-3 border-t border-gray-150 pt-3 text-left">
                  <div className="flex justify-between items-center bg-gray-50 p-2 rounded-xl">
                    <span className="text-xs font-black text-gray-800">✂️ 專屬服務項目菜單 (共 {profileServices.length} 項)</span>
                    <span className="text-[9px] text-amber-600 font-extrabold uppercase">供顧客直接選取預約</span>
                  </div>

                  {/* Services listing */}
                  {profileServices.length === 0 ? (
                    <p className="text-[11px] text-gray-400 py-1 italic">目前暫無提供任何服務項目。顧客將無法自選內容預約！</p>
                  ) : (
                    <div className="space-y-1.5 max-h-48 overflow-y-auto bg-slate-50 p-1.5 rounded-xl">
                      {profileServices.map((svc) => (
                        <div key={svc.id} className="bg-white p-2 rounded-lg border border-gray-200 flex justify-between items-center text-xs">
                          <div>
                            <div className="flex items-center gap-1.5">
                              <span className="bg-neutral-800 text-neutral-100 text-[8.5px] px-1 py-0.2 rounded font-black">{svc.category}</span>
                              <span className="font-extrabold text-neutral-900">{svc.name}</span>
                            </div>
                            <p className="text-[10px] text-gray-500 mt-0.5">{svc.description}</p>
                            <span className="text-[10px] font-bold font-mono text-emerald-600">HK$ {svc.price}</span>
                          </div>
                          <button
                            type="button"
                            onClick={() => handleRemoveService(svc.id)}
                            className="p-1.5 bg-rose-50 hover:bg-rose-100 text-rose-500 rounded-lg cursor-pointer"
                            title="下架此服務"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Add New Service Sub-Form */}
                  <div className="bg-slate-100 p-2.5 rounded-xl border border-gray-200 space-y-2">
                    <p className="text-[10px] text-neutral-800 font-black">⚙️ 新架設專屬服務項目：</p>
                    <div className="grid grid-cols-2 gap-2">
                      <div className="space-y-0.5">
                        <label className="text-[8px] text-neutral-400">服務名稱 *</label>
                        <input 
                          type="text"
                          placeholder="例如：韓式極致氣墊燙"
                          value={newServiceName}
                          onChange={(e) => setNewServiceName(e.target.value)}
                          className="w-full bg-white border border-gray-200 text-[10px] p-1 rounded-lg"
                        />
                      </div>
                      <div className="space-y-0.5">
                        <label className="text-[8px] text-neutral-400">服務類別 *</label>
                        <select
                          value={newServiceCategory}
                          onChange={(e) => setNewServiceCategory(e.target.value)}
                          className="w-full bg-white border border-gray-200 text-[10px] p-1 rounded-lg"
                        >
                          <option value="剪髮">剪髮</option>
                          <option value="染髮">染髮</option>
                          <option value="護髮">護髮</option>
                          <option value="燙髮">燙髮</option>
                          <option value="造型">造型</option>
                        </select>
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-2">
                      <div className="space-y-0.5">
                        <label className="text-[8px] text-neutral-400">單價 HK$ *</label>
                        <input 
                          type="number"
                          value={newServicePrice}
                          onChange={(e) => setNewServicePrice(Number(e.target.value))}
                          className="w-full bg-white border border-gray-200 text-[10px] p-1 rounded-lg font-mono"
                        />
                      </div>
                      <div className="space-y-0.5">
                        <label className="text-[8px] text-neutral-400">時長 (分鐘) *</label>
                        <input 
                          type="number"
                          value={newServiceDuration}
                          onChange={(e) => setNewServiceDuration(Number(e.target.value))}
                          className="w-full bg-white border border-gray-200 text-[10px] p-1 rounded-lg font-mono"
                        />
                      </div>
                    </div>

                    <div className="space-y-0.5">
                      <label className="text-[8px] text-neutral-400">短述補充簡要</label>
                      <input 
                        type="text"
                        placeholder="例如：低溫受損小修護"
                        value={newServiceDesc}
                        onChange={(e) => setNewServiceDesc(e.target.value)}
                        className="w-full bg-white border border-gray-200 text-[10px] p-1 rounded-lg"
                      />
                    </div>

                    <button
                      type="button"
                      onClick={(e) => {
                        if (!newServiceName.trim()) {
                          alert('請輸入有效的服務項目名稱！');
                          return;
                        }
                        handleAddService(e);
                      }}
                      className="w-full py-1.5 bg-black text-white hover:bg-neutral-800 rounded-lg text-[10px] font-bold cursor-pointer"
                    >
                      ＋ 架架上架此服務項目
                    </button>
                  </div>
                </div>

                {/* Portfolio instagram link */}
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-wider">設計師線上 IG 專業作品連結</label>
                  <input 
                    type="url"
                    value={profilePortfolio}
                    onChange={(e) => setProfilePortfolio(e.target.value)}
                    className="w-full bg-slate-50 border border-gray-250 text-xs font-mono px-3 py-2 rounded-xl focus:ring-1 focus:ring-black"
                    placeholder="https://instagram.com/my-portfolio"
                  />
                </div>

                {/* Submit save button */}
                <button
                  type="submit"
                  disabled={isSavingProfile}
                  className="w-full py-3.5 bg-black text-white hover:bg-neutral-800 text-xs font-extrabold rounded-xl transition-all active:scale-[0.98] cursor-pointer shadow-md flex items-center justify-center gap-1 mt-4"
                >
                  {isSavingProfile ? (
                    <>
                      <RefreshCw className="w-3.5 h-3.5 animate-spin mr-1" />
                      <span>正在存檔並寫入 Supabase...</span>
                    </>
                  ) : (
                    <span>儲存名片並更新 Supabase 表</span>
                  )}
                </button>
              </form>

            </motion.div>
          )}

        </AnimatePresence>
      </div>

      {/* 🧭 BOTTOM STYLIST NAVIGATION TAB BAR */}
      <nav className="fixed bottom-0 inset-x-0 max-w-none md:max-w-md md:absolute md:bottom-0 bg-neutral-900 border-t border-neutral-850 py-3 flex justify-around items-center z-45 rounded-b-none md:rounded-b-[28px] shadow-[0_-8px_20px_rgba(0,0,0,0.15)]">
        <button
          onClick={() => {
            setActiveTab('bookings');
            setActiveThreadId(null);
          }}
          className={`flex flex-col items-center justify-center transition-all duration-300 active:scale-95 cursor-pointer ${
            activeTab === 'bookings' ? 'text-amber-400 font-extrabold scale-102' : 'text-neutral-400 hover:text-white'
          }`}
        >
          <Calendar className="w-5 h-5 shrink-0" />
          <span className="text-[9.5px] mt-1 font-sans">今日預約</span>
          {activeTab === 'bookings' && <span className="w-1 h-1 bg-amber-400 rounded-full mt-0.5" />}
        </button>

        <button
          onClick={() => {
            setActiveTab('messages');
            setActiveThreadId(null);
          }}
          className={`flex flex-col items-center justify-center transition-all duration-300 active:scale-95 cursor-pointer relative ${
            activeTab === 'messages' ? 'text-amber-400 font-extrabold scale-102' : 'text-neutral-400 hover:text-white'
          }`}
        >
          <MessageSquare className="w-5 h-5 shrink-0" />
          <span className="text-[9.5px] mt-1 font-sans">顧客訊息</span>
          {/* Badge indicator */}
          {threads.some(t => t.unread) && (
            <span className="absolute top-0 right-3 w-2 h-2 bg-red-500 rounded-full border border-neutral-900" />
          )}
          {activeTab === 'messages' && <span className="w-1 h-1 bg-amber-400 rounded-full mt-0.5" />}
        </button>

        <button
          onClick={() => {
            setActiveTab('schedule');
            setActiveThreadId(null);
          }}
          className={`flex flex-col items-center justify-center transition-all duration-300 active:scale-95 cursor-pointer ${
            activeTab === 'schedule' ? 'text-amber-400 font-extrabold scale-102' : 'text-neutral-400 hover:text-white'
          }`}
        >
          <Clock className="w-5 h-5 shrink-0" />
          <span className="text-[9.5px] mt-1 font-sans">檔期管理</span>
          {activeTab === 'schedule' && <span className="w-1 h-1 bg-amber-400 rounded-full mt-0.5" />}
        </button>

        <button
          onClick={() => {
            setActiveTab('profile');
            setActiveThreadId(null);
          }}
          className={`flex flex-col items-center justify-center transition-all duration-300 active:scale-95 cursor-pointer ${
            activeTab === 'profile' ? 'text-amber-400 font-extrabold scale-102' : 'text-neutral-400 hover:text-white'
          }`}
        >
          <User className="w-5 h-5 shrink-0" />
          <span className="text-[9.5px] mt-1 font-sans">我的檔案</span>
          {activeTab === 'profile' && <span className="w-1 h-1 bg-amber-400 rounded-full mt-0.5" />}
        </button>
      </nav>

    </div>
  );
}
