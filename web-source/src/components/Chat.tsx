import React, { useState, useRef, useEffect } from 'react';
import { stylistsData, salonsData } from '../data';
import { ChatMessage, Stylist, Service } from '../types';
import { 
  ChevronLeft, ChevronRight, Phone, MoreVertical, Camera, Smile, Send, Info,
  Check, CheckCheck, Sparkles, Image, ShieldAlert, Ban, AlertTriangle, 
  Trash2, X, ExternalLink, Calendar, DollarSign, Bell, CheckCircle2, FileText
} from 'lucide-react';

interface ChatProps {
  onBack: () => void;
}

interface EnhancedMessage extends ChatMessage {
  isImg?: boolean;
  imgUrl?: string;
  isOffer?: boolean;
  offerTitle?: string;
  offerPrice?: number;
  offerAccepted?: boolean;
  isBookingShare?: boolean;
  bookingDetail?: {
    date: string;
    time: string;
    service: string;
    salon: string;
  };
  isRecalled?: boolean;
}

type StylistOnlineStatus = '在線上' | '忙碌中' | '工作中' | '離線中';

// Predefined dialogue responses based on custom message keywords to simulate context-aware AI / synchronized messaging
const CUSTOM_RESPONSES: Record<string, string[]> = {
  '漂': [
    '我們店內使用的是義大利有機無損溫和漂粉，能將毛鱗片傷害降至最低！請問您以前有染過黑色、紅色或者是自己DIY泡泡染過嗎？這會影響漂髮的乾淨度喔。',
    '如果是挑染或者Balayage，有些亮色是必须漂1-2次的。我可以幫您加入深層「黑曜光」鏈鍵修護，染完頭髮依然超級有彈性光澤！'
  ],
  '剪': [
    '好的，剪髮方面我非常注重臉型修飾。例如精緻羽毛剪或者日系高層次，都可以完美修飾額頭和下顎線。您可以分享幾張喜歡的明星髮型給我！',
    '我的洗剪套餐通常包含了深層舒壓洗髮以及吹風修飾造型，過程大約60分鐘。'
  ],
  '燙': [
    '韓式氣墊燙、水波紋或者木馬卷是我非常擅長的項目！我們會根據您的髮質搭配適合的溫塑藥水，燙出來的弧度就像剛吹好一樣Q彈。',
    '想請問您最近半年內有漂過頭髮嗎？如果漂過的話，一般不建議直接進行高溫熱塑燙，我們可以改做縮毛矯正或蛋白修護喔！'
  ],
  '價': [
    '我目前的主打項目都在服務清單中，透明公開。我可以立刻為您發送一份專屬客製作物「數位報價單卡片」，您可以直接在聊天室內同意並確認，非常方便！',
    '我的基礎剪髮是 HK$ 80 起，如果需要做歐美挑染或縮毛矯正一般在 HK$ 220 - 320 左右，具體看您的頭髮長度與受損程度。'
  ],
  'default': [
    '了解您的想法，我會全力協助您！我非常看重客製化溝通，建議您可以點選左側的「＋」分享您有興趣的「髮型大片展示」或者「預訂明細卡片」給我，以便隨時幫您對齊排程。',
    '收到！您的髮況和想要呈現的層次我記下來了。店內目前正舉辦限時優惠，您可以直接前往我的「個人檔案」挑選時段，或直接在這裡向我提問。'
  ]
};

// Initial messages database mapped by stylist ID
const INITAL_CHATS_BY_STYLIST: Record<string, EnhancedMessage[]> = {
  'master-leo': [
    {
      id: 'ml_1',
      senderId: 'stylist',
      senderName: 'Master Leo',
      text: '您好！我是 尖沙咀海港城 的首席設計師 Master Leo。很高興能為您服務。請問今天想諮詢什麼樣的髮型挑戰或調整呢？',
      time: '12:05'
    },
    {
      id: 'ml_2',
      senderId: 'user',
      senderName: 'Alex',
      text: '你好，我想嘗試最近流行的巴黎畫染 (Balayage)，但不確定我的髮質是否適合。',
      time: '12:08'
    },
    {
      id: 'ml_3',
      senderId: 'stylist',
      senderName: 'Master Leo',
      text: '巴黎畫染非常適合增加頭髮的層次感與立體線條！為了能給您更精確的建議，可以請您上傳一張您目前的頭髮近照嗎？特別是髮尾的受損狀況與目前的髮色。',
      time: '12:09'
    }
  ],
  'alex-chen': [
    {
      id: 'ac_1',
      senderId: 'stylist',
      senderName: 'Alex Chen',
      text: '哈囉！我是 Alex，專攻英式漸層和男士油頭、歐美高明度漂染。有什麼髮型靈感想要聊聊的嗎？',
      time: '昨日 15:30'
    },
    {
      id: 'ac_2',
      senderId: 'user',
      senderName: 'Alex',
      text: '我的側邊頭髮很容易炸開蓬起來，請問做漸層推剪能維持多久？',
      time: '昨日 15:42'
    },
    {
      id: 'ac_3',
      senderId: 'stylist',
      senderName: 'Alex Chen',
      text: '這很常見！亞洲人髮質偏硬，側邊特別容易橫向炸開。我通常會做 Down Perm (兩側壓貼燙) 或者是精細的漸層推剪，大約可以完美维持 3 至 4 週。要不要看看我的復古漸層作品？',
      time: '昨日 15:45'
    }
  ],
  'sarah-lin': [
    {
      id: 'sl_1',
      senderId: 'stylist',
      senderName: 'Sarah Lin',
      text: '안녕～ 您好！我是 Sarah 🙋‍♀️ 專注氣墊燙與女神波浪卷。很多女生擔心燙完會顯老或難整理，交給我完全不用擔心喔！',
      time: '星期二 10:15'
    },
    {
      id: 'sl_2',
      senderId: 'user',
      senderName: 'Alex',
      text: '哈囉，我的臉型偏圓，燙浪漫大卷會顯得胖嗎？',
      time: '星期二 10:20'
    },
    {
      id: 'sl_3',
      senderId: 'stylist',
      senderName: 'Sarah Lin',
      text: '完全不會！我會特別在額角兩側設計「法式八字劉海」和層次墊高，這樣能拉長臉型比例，製造極佳的修容視覺，看起來既減齡臉又小喔！',
      time: '星期二 10:22'
    }
  ],
  'jessica-ho': [
    {
      id: 'jh_1',
      senderId: 'stylist',
      senderName: 'Jessica Ho',
      text: '您好！我是 Jessica。我專精縮毛矯正和深層重塑護理，致力於把自然捲與極度毛糙受損的頭髮，挽救回鏡面般絲滑的質感！',
      time: '星期一 11:20'
    }
  ]
};

// Preset images for mock reference selection (Hairstyles search & sharing)
const PRESET_HAIRSTYLES = [
  { id: 'h1', title: '冷灰色手刷畫染 Balayage', r: 'Master Leo', url: 'https://images.unsplash.com/photo-1595959183075-c1d0a174db24?auto=format&fit=crop&w=300&q=80' },
  { id: 'h2', title: '韓式外翻八字大波浪', r: 'Sarah Lin', url: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=300&q=80' },
  { id: 'h3', title: '法式清透中長鮑伯剪裁', r: 'Master Leo', url: 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=300&q=80' },
  { id: 'h4', title: '英倫復古極致漸層油頭', r: 'Alex Chen', url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDlNSboCB_LPxPyFQTDFM9AEOOHcj9F4Dp9mXvFKod_jFuRX6OWJzn4xQQNDv1XuYDovw296jBa947P8pAB5ULQcw3wGQh5tmkzzPijSqcumikD4KrBEs1aOl1uWUnJV7_vMUBhhC5eWsdvTWrg_LJG6GJA27GrYmcDNcA-qwX6C61CjiIyTnf4GbFXcjPfSmW8KzlZXrinFG5wa_a6GTBTTQKaBFzocjyiNtiqd1QC1jM44xkt9iRrPdRwjgRX6S3aMxp4LIJAqy8' }
];

// Preset custom mock user uploaded current hair screenshots
const PRESET_USER_HAIRS = [
  { id: 'u_h1', title: '受損乾枯毛躁金髮', desc: '漂過2次，髮尾極乾', url: 'https://images.unsplash.com/photo-1592188615439-74677248e533?auto=format&fit=crop&w=300&q=80' },
  { id: 'u_h2', title: '黑髮自然捲長髮', desc: '自然捲严重，極易扁塌蓬亂', url: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=300&q=80' },
  { id: 'u_h3', title: '中等長度布丁頭', desc: '原生髮已長出10cm，分層嚴重', url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80' }
];

export default function Chat({ onBack }: ChatProps) {
  // Inbox viewMode switcher ('inbox' -> conversation lists page; 'chat' -> 1-on-1 detail chat view)
  const [viewMode, setViewMode] = useState<'inbox' | 'chat'>('inbox');

  // Red dot reminders map
  const [unreadMap, setUnreadMap] = useState<Record<string, boolean>>({
    'master-leo': false,
    'alex-chen': false,
    'sarah-lin': true, // preset true for beautiful red dot demo on startup
    'jessica-ho': false
  });

  // Active selected conversational partner stylist
  const [activeStylistId, setActiveStylistId] = useState<string>('master-leo');
  const stylist = stylistsData.find(s => s.id === activeStylistId) || stylistsData[0];

  // Chats container mapped locally to remember conversation across tabs
  const [chats, setChats] = useState<Record<string, EnhancedMessage[]>>(INITAL_CHATS_BY_STYLIST);
  const messages = chats[activeStylistId] || [];

  // Local file picker for real photo upload sending
  const handlePhotoFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      if (typeof reader.result === 'string') {
        handleSendMessage('📷 分享了一張髮況相片', {
          isImg: true,
          imgUrl: reader.result
        });
      }
    };
    reader.readAsDataURL(file);
  };

  const [inputText, setInputText] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [typingName, setTypingName] = useState('');

  // Seen check states tracker
  const [seenStatus, setSeenStatus] = useState<Record<string, 'sent' | 'delivered' | 'seen'>>({});

  // Additional settings panels toggle state
  const [showAttachments, setShowAttachments] = useState(false);
  const [showMoreMenu, setShowMoreMenu] = useState(false);
  const [isBlocked, setIsBlocked] = useState<Record<string, boolean>>({});

  // Report details state
  const [showReportModal, setShowReportModal] = useState(false);
  const [reportReason, setReportReason] = useState(' harassment ');
  const [reportComment, setReportComment] = useState('');

  // Internal simulated push notifications list
  const [pushNotifications, setPushNotifications] = useState<any[]>([]);

  // Ref scroll to bottom
  const chatBottomRef = useRef<HTMLDivElement>(null);

  // Synthesize a beautiful instant messenger system sound safely on client-side
  const playSoundEffect = (type: 'send' | 'recv' | 'notify') => {
    try {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioContextClass) return;
      const ctx = new AudioContextClass();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      
      osc.connect(gain);
      gain.connect(ctx.destination);
      
      if (type === 'send') {
        osc.frequency.setValueAtTime(650, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 0.15);
        gain.gain.setValueAtTime(0.08, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.15);
        osc.start();
        osc.stop(ctx.currentTime + 0.15);
      } else if (type === 'recv') {
        osc.frequency.setValueAtTime(880, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(520, ctx.currentTime + 0.2);
        gain.gain.setValueAtTime(0.12, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.2);
        osc.start();
        osc.stop(ctx.currentTime + 0.2);
      } else if (type === 'notify') {
        osc.frequency.setValueAtTime(520, ctx.currentTime);
        osc.frequency.setValueAtTime(780, ctx.currentTime + 0.08);
        gain.gain.setValueAtTime(0.1, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.25);
        osc.start();
        osc.stop(ctx.currentTime + 0.25);
      }
    } catch (e) {
      // Audio auto-play policy catch-all
    }
  };

  // Safe scheduler helper for scrolling
  const scrollToBottom = () => {
    setTimeout(() => {
      chatBottomRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, 100);
  };

  // Settle scrolling whenever switching stylist conversation
  useEffect(() => {
    scrollToBottom();
    setShowAttachments(false);
    setShowMoreMenu(false);
  }, [activeStylistId]);

  // Push notifications simulation timeline triggers
  useEffect(() => {
    const notifyTimer = setTimeout(() => {
      // Trigger a beautiful push notification from Jessica Ho
      const inactiveId = activeStylistId === 'jessica-ho' ? 'sarah-lin' : 'jessica-ho';
      const sender = stylistsData.find(s => s.id === inactiveId) || stylistsData[3];
      
      const newNotify = {
        id: 'push_' + Date.now(),
        stylistId: sender.id,
        name: sender.name,
        avatar: sender.avatar,
        text: '哈囉！看到你對髮型設計有興趣，我新增了最新的「黑曜光直順縮毛」修復包，歡迎點此預約諮詢！✨'
      };

      playSoundEffect('notify');
      setPushNotifications(prev => [newNotify, ...prev]);

      // Set UNREAD red dot indicator on the conversation list so inbox shows red dot!
      setUnreadMap(prev => ({ ...prev, [sender.id]: true }));

      // Append new incoming simulated message directly to the chat database
      const replyMsg: EnhancedMessage = {
        id: 'msg_recv_push_' + Date.now(),
        senderId: 'stylist',
        senderName: sender.name,
        text: '哈囉！看到你對髮型設計有興趣，我新增了最新的「黑曜光直順縮毛」修復包，歡迎點此預約諮詢！✨',
        time: getCurrentTime()
      };

      setChats(prev => {
        const existing = prev[sender.id] || [];
        return {
          ...prev,
          [sender.id]: [...existing, replyMsg]
        };
      });

      // Dismiss automatically after 7 seconds
      setTimeout(() => {
        setPushNotifications(prev => prev.filter(n => n.id !== newNotify.id));
      }, 7000);

    }, 18000);

    return () => clearTimeout(notifyTimer);
  }, [activeStylistId]);

  const getCurrentTime = (): string => {
    const d = new Date();
    return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  };

  // core send message function
  const handleSendMessage = (text: string, options: Partial<EnhancedMessage> = {}) => {
    if (isBlocked[activeStylistId]) {
      alert('請先解除封鎖此設計師以繼續對話。');
      return;
    }

    const cleanText = text.trim();
    if (!cleanText && !options.isImg && !options.isBookingShare && !options.isOffer) return;

    const messageId = 'msg_user_' + Date.now();
    const newMsg: EnhancedMessage = {
      id: messageId,
      senderId: 'user',
      senderName: 'Alex',
      text: cleanText,
      time: getCurrentTime(),
      ...options
    };

    playSoundEffect('send');
    
    // Update local chat sequence
    setChats(prev => {
      const existing = prev[activeStylistId] || [];
      return {
        ...prev,
        [activeStylistId]: [...existing, newMsg]
      };
    });

    setInputText('');
    setShowAttachments(false);
    scrollToBottom();

    // Mark delivery sequence
    setSeenStatus(prev => ({ ...prev, [messageId]: 'sent' }));
    
    setTimeout(() => {
      setSeenStatus(prev => ({ ...prev, [messageId]: 'delivered' }));
    }, 600);

    setTimeout(() => {
      setSeenStatus(prev => ({ ...prev, [messageId]: 'seen' }));
    }, 1200);

    // AI Dynamic Typing response simulation
    setTimeout(() => {
      setIsTyping(true);
      setTypingName(stylist.name);
      scrollToBottom();

      // Formulate smart responses based on user query keywords
      setTimeout(() => {
        setIsTyping(false);
        
        let responseCandidates = CUSTOM_RESPONSES.default;
        const lowerInput = cleanText.toLowerCase();

        if (lowerInput.includes('漂') || lowerInput.includes('色') || lowerInput.includes('染')) {
          responseCandidates = CUSTOM_RESPONSES['漂'];
        } else if (lowerInput.includes('剪') || lowerInput.includes('刀') || lowerInput.includes('修')) {
          responseCandidates = CUSTOM_RESPONSES['剪'];
        } else if (lowerInput.includes('燙') || lowerInput.includes('卷') || lowerInput.includes('捲')) {
          responseCandidates = CUSTOM_RESPONSES['燙'];
        } else if (lowerInput.includes('價') || lowerInput.includes('錢') || lowerInput.includes('收費') || lowerInput.includes('貴')) {
          responseCandidates = CUSTOM_RESPONSES['價'];
        }

        // Pick random response from candidates
        const replyText = responseCandidates[Math.floor(Math.random() * responseCandidates.length)];

        const replyMsg: EnhancedMessage = {
          id: 'msg_stylist_' + Date.now(),
          senderId: 'stylist',
          senderName: stylist.name,
          text: replyText,
          time: getCurrentTime()
        };

        playSoundEffect('recv');
        setChats(prev => {
          const existing = prev[activeStylistId] || [];
          return {
            ...prev,
            [activeStylistId]: [...existing, replyMsg]
          };
        });

        scrollToBottom();
      }, 1600);

    }, 2200);
  };

  // Recall / Unsend user message (Requirement: 訊息撤回)
  const handleRecallMessage = (id: string) => {
    setChats(prev => {
      const currentList = prev[activeStylistId] || [];
      const updatedList = currentList.map(msg => {
        if (msg.id === id) {
          return {
            ...msg,
            text: '⚠️ 此儲值訊息已被您成功撤回。',
            isRecalled: true,
            isImg: false,
            isOffer: false,
            isBookingShare: false
          };
        }
        return msg;
      });
      return {
        ...prev,
        [activeStylistId]: updatedList
      };
    });
    alert('🎉 訊息已成功撒回 (Unsent)。對方聊天視窗中的此條內容已被同步清除！');
  };

  // Block handler toggles (Requirement: 封鎖功能)
  const toggleBlockStylist = () => {
    const isNowBlocked = !isBlocked[activeStylistId];
    setIsBlocked(prev => ({ ...prev, [activeStylistId]: isNowBlocked }));
    setShowMoreMenu(false);
    if (isNowBlocked) {
      alert(`🚫 已將設計師「${stylist.name}」移至黑名單並封鎖。您不再收到對方的任何即時更新或推播。`);
    } else {
      alert(`🟢 已解除對「${stylist.name}」的封鎖，您可以開始發送訊息。`);
    }
  };

  // Report form handler submission (Requirement: 舉報功能)
  const handleSubmitReport = (e: React.FormEvent) => {
    e.preventDefault();
    setShowReportModal(false);
    setReportComment('');
    alert(`🎉 您的檢舉與聊天存檔已安全傳送至 AI Studio 客服稽核組。我們將在2小時內審核設計師「${stylist.name}」的對話行為，如有違法推廣或虛假作品，將立即封禁其商戶資格！`);
  };

  // Custom Quick Share selections (Images, Books, Quotations)
  const shareHairstylePhoto = (title: string, url: string) => {
    // Shares a beautiful style reference card
    handleSendMessage(`💇‍♂️ [分享髮型作品] - 我對「${title}」這款非常感興趣，請問我的長度適合用這個效果嗎？`, {
      isImg: true,
      imgUrl: url
    });
  };

  const shareMyHairState = (hairTitle: string, url: string) => {
    // Shares actual hair status to simulated consulting
    handleSendMessage(`📷 [上傳個人髮照] - 我的目前髮況款式是：「${hairTitle}」。`, {
      isImg: true,
      imgUrl: url
    });
  };

  const shareUpcomingBookingCard = () => {
    // Share a simulated pending booking ticket
    handleSendMessage(`📅 [預約資訊卡片] - 我想要為我的這筆預約單進行預先髮況溝通：`, {
      isBookingShare: true,
      bookingDetail: {
        date: '2026-06-10 (星期三)',
        time: '14:30',
        service: '經典洗剪設計大師套餐',
        salon: stylist.id === 'master-leo' ? 'Maison de Beauté (尖沙咀海港城)' : '高級專業連鎖沙龍店'
      }
    });
  };

  const shareStylistPriceQuotations = () => {
    // Share a luxury digital quotation offer bill
    const priceTitle = stylist.services[0]?.name || '客製色光漂染護理';
    const priceNum = stylist.services[0]?.price || 150;
    
    // Simulate sender from stylist (sent by stylist to client)
    const quoteMsg: EnhancedMessage = {
      id: 'quote_' + Date.now(),
      senderId: 'stylist',
      senderName: stylist.name,
      text: `💰 [專屬沙龍電子報價單] - 已為您申請專屬 VIP 特惠價：`,
      time: getCurrentTime(),
      isOffer: true,
      offerTitle: `${priceTitle} (含微分子深層蒸氣水護理)`,
      offerPrice: Math.round(priceNum * 0.9), // offering special discount
      offerAccepted: false
    };

    playSoundEffect('recv');
    setChats(prev => {
      const existing = prev[activeStylistId] || [];
      return {
        ...prev,
        [activeStylistId]: [...existing, quoteMsg]
      };
    });
    setShowAttachments(false);
    scrollToBottom();
  };

  const handleAcceptQuoteOffer = (msgId: string) => {
    // Accept price quotation and instantly simulate conversion success
    setChats(prev => {
      const existing = prev[activeStylistId] || [];
      const updated = existing.map(msg => {
        if (msg.id === msgId) {
          return { ...msg, offerAccepted: true };
        }
        return msg;
      });
      return { ...prev, [activeStylistId]: updated };
    });
    alert('🎉 恭喜！您已成功接受此專屬報價單。系統已為您鎖定此限定折扣，並同步上傳此定單金額，快點击下方確認行程吧！');
  };

  // CHAT INBOX VIEWMODE EARLY RETURN
  if (viewMode === 'inbox') {
    return (
      <div className="w-full h-full bg-slate-50 flex flex-col justify-between relative overflow-hidden select-none font-sans">
        
        {/* hidden real input for camera device photos */}
        <input
          type="file"
          id="chat-photo-input-inbox"
          accept="image/*"
          className="hidden"
          onChange={handlePhotoFileChange}
        />

        {/* 🟢 TOP SIMULATED IN-APP FLOATING PUSH NOTIFICATIONS */}
        {pushNotifications.length > 0 && (
          <div className="absolute top-16 left-1/2 transform -translate-x-1/2 w-[92%] z-55 animate-bounce duration-300">
            {pushNotifications.map((noti) => (
              <div 
                key={noti.id}
                onClick={() => {
                  setActiveStylistId(noti.stylistId);
                  setPushNotifications([]);
                  setUnreadMap(prev => ({ ...prev, [noti.stylistId]: false }));
                  setViewMode('chat');
                }}
                className="bg-zinc-950 text-white rounded-2xl p-3.5 shadow-xl border border-zinc-800 flex gap-3 cursor-pointer hover:bg-zinc-900 transition-all"
              >
                <div className="w-10 h-10 rounded-full overflow-hidden shrink-0 border border-zinc-700 relative">
                  <img src={noti.avatar} alt="Notification Avatar" className="w-full h-full object-cover" />
                  <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 rounded-full border border-zinc-950 animate-ping"></span>
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex justify-between items-center">
                    <span className="font-extrabold text-[10px] text-amber-400">設計師新訊息 💬</span>
                    <span className="text-[8px] bg-red-650 text-white font-extrabold px-1.5 py-0.5 rounded-full uppercase tracking-wider">NEW</span>
                  </div>
                  <p className="font-bold text-xs text-zinc-100 truncate mt-0.5">{noti.name}</p>
                  <p className="text-[10px] text-zinc-300 truncate mt-0.5 font-normal leading-relaxed">{noti.text}</p>
                </div>
                <div className="shrink-0 flex items-center pl-1">
                  <ChevronRight className="w-4 h-4 text-zinc-400" />
                </div>
              </div>
            ))}
          </div>
        )}

        {/* A. INBOX CONTAINER PAGE */}
        <div className="w-full h-full flex flex-col bg-slate-50">
          
          {/* Header */}
          <header className="bg-white border-b border-gray-150 px-5 py-4.5 flex justify-between items-center shrink-0">
            <button
              onClick={onBack}
              className="active:scale-95 duration-150 p-2.5 hover:bg-gray-100 rounded-full cursor-pointer transition-all shrink-0 border border-gray-100 bg-white"
              title="返回首頁"
            >
              <ChevronLeft className="w-4 h-4 text-black stroke-[2.5]" />
            </button>
            <span className="font-sans font-black text-xs tracking-wider text-gray-900 uppercase">
              💇‍♂️ 髮師諮詢對話盒子 (INBOX)
            </span>
            <div className="w-9 h-9"></div>
          </header>

          {/* Info Banner */}
          <div className="px-5 py-3.5 bg-white border-b border-gray-100 shrink-0 space-y-1">
            <div className="flex justify-between items-center">
              <h2 className="text-xs font-black text-gray-950 uppercase tracking-wider">聯絡與行程諮詢對話</h2>
              <span className="text-[8.5px] bg-emerald-50 text-emerald-850 font-extrabold px-2 py-0.5 rounded-full border border-emerald-150/50">
                ● 點對點已加密
              </span>
            </div>
            <p className="text-[10.5px] text-gray-450 leading-relaxed font-sans">
              您在此處可以與為您服務過的設計師安全、即時在線聊天，無需跳轉 WhatsApp、LINE 或其他軟體。
            </p>
          </div>

          {/* Inbox threads list mapping */}
          <div className="flex-1 overflow-y-auto no-scrollbar pb-32 p-4.5 space-y-3.5 bg-slate-50">
            {stylistsData.map((sty) => {
              const chatList = chats[sty.id] || [];
              const lastMsg = chatList[chatList.length - 1];
              
              let lastMsgText = '尚未與設計師開始對話。';
              let lastMsgTime = '12:00';
              let isLastSenderUser = false;

              if (lastMsg) {
                lastMsgText = lastMsg.text || '📷 分享了媒體相片檔案';
                lastMsgTime = lastMsg.time || '12:05';
                isLastSenderUser = lastMsg.senderId === 'user';
              }

              const hasUnreadDot = unreadMap[sty.id];

              return (
                <div
                  key={sty.id}
                  onClick={() => {
                    setActiveStylistId(sty.id);
                    setUnreadMap(prev => ({ ...prev, [sty.id]: false }));
                    setViewMode('chat');
                    scrollToBottom();
                  }}
                  className="bg-white rounded-2xl border border-gray-150/70 p-4 shadow-5xs hover:border-black/55 hover:shadow-4xs transition-all duration-200 cursor-pointer flex gap-4 relative group"
                >
                  {/* RED UNREAD GLOWING DOT INDICATOR (有新訊息時，對話列表會有紅點提示) */}
                  {hasUnreadDot && (
                    <span className="absolute top-4 right-4 w-2.5 h-2.5 bg-red-500 rounded-full ring-4 ring-red-500/10 animate-pulse"></span>
                  )}

                  {/* Stylist Online Avatar */}
                  <div className="w-12 h-12 rounded-full overflow-hidden shrink-0 border border-gray-100 relative self-center group-hover:scale-102 transition-transform duration-350">
                    <img src={sty.avatar} alt={sty.name} className="w-full h-full object-cover animate-fade-in" />
                    <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 rounded-full border-2 border-white"></span>
                  </div>

                  {/* Body Info block of conversation */}
                  <div className="min-w-0 flex-1 space-y-1">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-1.5 min-w-0">
                        <h4 className="font-extrabold text-sm text-gray-950 font-sans truncate">
                          {sty.name}
                        </h4>
                        <span className="bg-slate-100 text-[8px] text-gray-500 font-extrabold px-1.5 py-0.2 rounded font-sans shrink-0 uppercase">
                          {sty.title}
                        </span>
                      </div>
                      <span className="text-[9.5px] text-gray-400 font-bold font-mono shrink-0 pr-4">
                        {lastMsgTime}
                      </span>
                    </div>

                    {/* Previews text content */}
                    <p className={`text-[11px] truncate leading-tight pr-6 ${
                      hasUnreadDot ? 'text-black font-extrabold font-sans' : 'text-gray-450'
                    }`}>
                      {isLastSenderUser && <span className="text-amber-600 font-extrabold mr-0.5">您:</span>}
                      {lastMsgText}
                    </p>

                    {/* Check indicator seen/unseen checkmark tags (顯示已讀或未讀) */}
                    <div className="flex justify-between items-center pt-2">
                      <div className="flex gap-1">
                        {sty.specialties.slice(0, 2).map((item) => (
                          <span key={item} className="text-[7.5px] font-black bg-slate-50 text-gray-400 border border-gray-100 px-1.5 py-0.5 rounded">
                            {item}
                          </span>
                        ))}
                      </div>

                      {/* Read status tag wrapper (顯示已讀或未讀) */}
                      <div>
                        {isLastSenderUser ? (
                          <span className="text-[8.5px] bg-amber-50 text-amber-700 font-black px-1.5 py-0.5 rounded-lg inline-flex items-center gap-0.5">
                            <span>已讀</span>
                            <CheckCheck className="w-2.5 h-2.5 stroke-[2.5]" />
                          </span>
                        ) : hasUnreadDot ? (
                          <span className="text-[8.5px] bg-red-50 text-red-650 font-black px-1.5 py-0.5 rounded-lg">
                            未讀 💬
                          </span>
                        ) : (
                          <span className="text-[8.5px] bg-slate-50 text-gray-400 font-bold px-1.5 py-0.5 rounded-lg">
                            已讀
                          </span>
                        )}
                      </div>
                    </div>

                  </div>
                </div>
              );
            })}
          </div>

        </div>

        {/* Bottom secure note footer */}
        <div className="p-4 text-center shrink-0 border-t border-gray-100 bg-white">
          <p className="text-[10px] text-gray-450 font-semibold uppercase tracking-wider">
            🔒 全程對講均支持 AES-256 水分子加密傳輸
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full h-full bg-slate-50 flex flex-col justify-between relative overflow-hidden select-none font-sans">
      
      {/* 🟢 TOP SIMULATED IN-APP FLOATING PUSH NOTIFICATIONS */}
      {pushNotifications.length > 0 && (
        <div className="absolute top-16 left-1/2 transform -translate-x-1/2 w-[92%] z-50 animate-bounce duration-300">
          {pushNotifications.map((noti) => (
            <div 
              key={noti.id}
              onClick={() => {
                setActiveStylistId(noti.stylistId);
                setPushNotifications([]);
              }}
              className="bg-zinc-950 text-white rounded-2xl p-3.5 shadow-xl border border-zinc-800 flex gap-3 cursor-pointer hover:bg-zinc-900 transition-all"
            >
              <div className="w-10 h-10 rounded-full overflow-hidden shrink-0 border border-zinc-700 relative">
                <img src={noti.avatar} alt="Notification Avatar" className="w-full h-full object-cover" />
                <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 rounded-full border border-zinc-950 animate-ping"></span>
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex justify-between items-center">
                  <span className="font-extrabold text-xs text-amber-400">設計師新訊息 💬</span>
                  <span className="text-[9px] bg-red-600 text-white font-extrabold px-1.5 py-0.5 rounded-full uppercase tracking-wider">即時</span>
                </div>
                <p className="font-bold text-xs text-zinc-100 truncate mt-0.5">{noti.name}</p>
                <p className="text-[10px] text-zinc-300 truncate mt-0.5 font-normal leading-relaxed">{noti.text}</p>
              </div>
              <div className="shrink-0 flex items-center pl-1">
                <ChevronRight className="w-4 h-4 text-zinc-400" />
              </div>
            </div>
          ))}
        </div>
      )}

      {/* 📱 ACTIVE CONTACTS CHATS SWITCHER HEADER (Requirement: 一對一聊天) */}
      <section className="bg-white shrink-0 w-full border-b border-gray-150 px-4 py-2 pt-3 flex gap-3 overflow-x-auto no-scrollbar items-center">
        <button
          onClick={() => setViewMode('inbox')}
          className="active:scale-95 duration-150 p-2.5 hover:bg-gray-100 rounded-full cursor-pointer transition-all shrink-0 border border-gray-100 bg-white"
          title="返回聯絡快收箱"
        >
          <ChevronLeft className="w-4 h-4 text-black stroke-[3px]" />
        </button>

        {stylistsData.map((sty) => {
          const isActive = stylist.id === sty.id;
          const blocked = isBlocked[sty.id];
          return (
            <button
              key={sty.id}
              onClick={() => setActiveStylistId(sty.id)}
              className={`flex items-center gap-2 p-1.5 px-3 rounded-full shrink-0 transition-all duration-300 border text-xs font-bold cursor-pointer ${
                isActive 
                  ? 'bg-neutral-900 border-neutral-900 text-white shadow-xs' 
                  : 'bg-white border-gray-150 hover:bg-slate-50 text-gray-700'
              }`}
            >
              <div className="relative shrink-0">
                <img
                  src={sty.avatar}
                  alt={sty.name}
                  className="w-5 h-5 rounded-full object-cover border border-gray-200"
                />
                {!blocked ? (
                  <span className="absolute -bottom-0.5 -right-0.5 w-1.8 h-1.8 bg-emerald-500 rounded-full border border-white"></span>
                ) : (
                  <span className="absolute -bottom-0.5 -right-0.5 w-1.8 h-1.8 bg-zinc-400 rounded-full border border-white"></span>
                )}
              </div>
              <span>{sty.name}</span>
              {blocked && <span className="text-[9px] bg-red-100 text-red-600 px-1 rounded">封鎖</span>}
            </button>
          );
        })}
      </section>

      {/* 👤 TOP SELECTED PROFILE BAR DETAILS WITH OPTIONS MENU */}
      <nav className="bg-slate-50/95 backdrop-blur-md shrink-0 w-full flex justify-between items-center px-5 py-3 border-b border-gray-100 z-10">
        <div className="flex items-center gap-3 min-w-0">
          <div className="relative shrink-0">
            <img
              alt={`${stylist.name} Headshot`}
              className="w-10 h-10 rounded-full object-cover border border-white shadow-2xs"
              src={stylist.avatar}
              referrerPolicy="no-referrer"
            />
            {!isBlocked[stylist.id] ? (
              <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-white rounded-full animate-pulse" title="目前在線上"></span>
            ) : (
              <span className="absolute bottom-0 right-0 w-3 h-3 bg-zinc-400 border-2 border-white rounded-full" title="已將其封鎖"></span>
            )}
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-1.5">
              <h1 className="font-sans font-bold text-sm text-gray-950 truncate">{stylist.name}</h1>
              <span className="bg-amber-400 text-black text-[8px] font-black px-1.5 py-0.5 rounded-sm">
                PRO
              </span>
            </div>
            <p className="text-[10px] text-gray-400 font-bold uppercase tracking-wider leading-none mt-0.5">
              {isBlocked[stylist.id] ? '🔒 已封鎖對話' : '🟢 在線：10年資歷專業設計師'}
            </p>
          </div>
        </div>

        {/* Action icons */}
        <div className="flex items-center gap-1 shrink-0 relative">
          <button 
            onClick={() => alert(`正在發起致電致 ${stylist.name} 私人語音通話...`)}
            className="p-2.5 text-black hover:bg-gray-100 rounded-full active:scale-95 transition-all cursor-pointer"
            title="語音電話"
          >
            <Phone className="w-[18px] h-[18px]" />
          </button>
          <button 
            onClick={() => setShowMoreMenu(!showMoreMenu)}
            className="p-2.5 text-black hover:bg-gray-100 rounded-full active:scale-95 transition-all cursor-pointer bg-white shadow-3xs"
            title="更多設定項目"
          >
            <MoreVertical className="w-[18px] h-[18px]" />
          </button>

          {/* MORE DROPDOWN PRESET PANEL (Requirements: 封鎖、舉報) */}
          {showMoreMenu && (
            <div className="absolute right-0 top-12 bg-white rounded-2xl p-2.5 shadow-xl border border-gray-100 min-w-[200px] z-50 animate-fade-in text-xs font-bold leading-normal">
              
              <div className="p-2 text-gray-400 text-[10px] font-heavy tracking-wider uppercase border-b border-gray-50 mb-1">
                通訊與帳號安全設定
              </div>

              <button
                onClick={toggleBlockStylist}
                className="w-full text-left p-2.5 hover:bg-red-50 text-red-600 rounded-xl flex items-center gap-2 cursor-pointer transition-colors"
              >
                <Ban className="w-4 h-4 shrink-0" />
                <span>{isBlocked[stylist.id] ? '🟢 解除封鎖設計師' : '⛔ 封鎖此設計師'}</span>
              </button>

              <button
                onClick={() => {
                  setShowReportModal(true);
                  setShowMoreMenu(false);
                }}
                className="w-full text-left p-2.5 hover:bg-amber-50 text-amber-800 rounded-xl flex items-center gap-2 cursor-pointer transition-colors"
              >
                <AlertTriangle className="w-4 h-4 shrink-0" />
                <span>⚠️ 舉報違規商業行為</span>
              </button>

              <button
                onClick={() => {
                  alert('🔒 本通訊均已啟用 AES-256 全程點對點專利加密技術，保障您的髮型設計諮詢和肖像隱私權。');
                  setShowMoreMenu(false);
                }}
                className="w-full text-left p-2.5 hover:bg-slate-50 text-gray-700 rounded-xl flex items-center gap-2 cursor-pointer transition-colors border-t border-gray-50 mt-1"
              >
                <Info className="w-4 h-4 shrink-0 text-gray-400" />
                <span>安全對點加密條款</span>
              </button>

            </div>
          )}
        </div>
      </nav>

      {/* 💬 MAIN CHAT LOGGER CANVAS WINDOW */}
      <main className="flex-1 overflow-y-auto px-5 py-4 space-y-4 no-scrollbar relative min-h-0">
        
        {/* Safe advice line */}
        <div className="flex justify-center my-1">
          <span className="bg-gray-200/50 text-gray-500 font-extrabold text-[9px] px-3.5 py-1 rounded-full uppercase tracking-widest flex items-center gap-1 border border-gray-100 shadow-3xs">
            🛡️ 點對點極高安全盾通道保障中
          </span>
        </div>

        {/* Existing loaded dialog list */}
        {messages.map((m) => {
          const isUser = m.senderId === 'user';
          return (
            <div
              key={m.id}
              className={`flex items-end gap-2 max-w-[88%] relative group ${
                isUser ? 'ml-auto flex-row-reverse' : ''
              }`}
            >
              {/* Profile image icon next to messages */}
              {!isUser && (
                <div className="w-8 h-8 rounded-full overflow-hidden shrink-0 border border-gray-150 self-start mt-0.5">
                  <img src={stylist.avatar} alt="Barber" className="w-full h-full object-cover" />
                </div>
              )}

              {/* Message bubbles wrapper context */}
              <div className="space-y-1 max-w-full">
                
                {/* Visual rendering of message content */}
                <div
                  className={`p-4 rounded-2xl border relative flex flex-col gap-2 ${
                    isUser
                      ? 'bg-neutral-950 text-white border-neutral-900 rounded-tr-none shadow-3xs'
                      : 'bg-white text-gray-800 border-gray-100 rounded-tl-none shadow-5xs'
                  }`}
                >
                  
                  {/* Recalled states */}
                  {m.isRecalled ? (
                    <div className="flex items-center gap-1.5 italic text-[11px] text-gray-400 font-medium">
                      <ShieldAlert className="w-3.5 h-3.5" />
                      <span>{m.text}</span>
                    </div>
                  ) : (
                    <>
                      {/* Original text content */}
                      {m.text && <p className="text-xs leading-relaxed font-sans">{m.text}</p>}

                      {/* Style portfolio reference image attachment */}
                      {m.isImg && m.imgUrl && (
                        <div className="rounded-xl overflow-hidden mt-1 max-w-[210px] aspect-square border border-gray-150 bg-slate-50 relative group">
                          <img
                            src={m.imgUrl}
                            alt="Reference Attachment"
                            className="w-full h-full object-cover"
                            referrerPolicy="no-referrer"
                          />
                          <div className="absolute inset-x-0 bottom-0 p-1.5 bg-gradient-to-t from-black/80 via-black/20 to-transparent">
                            <span className="text-[10px] font-bold text-white text-ellipsis block tracking-tight">
                              點選可預覽原尺寸
                            </span>
                          </div>
                        </div>
                      )}

                      {/* Client shared upcoming bookings ticket (Requirement: 預約卡片分享) */}
                      {m.isBookingShare && m.bookingDetail && (
                        <div className="bg-amber-50 rounded-xl p-3 border border-amber-200 mt-1 space-y-2 text-gray-900 max-w-[210px]">
                          <p className="text-[10px] bg-amber-400 text-black font-black px-1.5 py-0.5 rounded inline-block uppercase tracking-wider leading-none">
                            預約明細卡
                          </p>
                          <div className="space-y-1">
                            <p className="font-extrabold text-[11px] font-sans text-amber-900 truncate">
                              {m.bookingDetail.service}
                            </p>
                            <p className="text-[10px] text-gray-600 font-medium leading-relaxed">
                              日期: {m.bookingDetail.date}
                            </p>
                            <p className="text-[10px] text-gray-600 font-medium leading-relaxed">
                              時間: {m.bookingDetail.time}
                            </p>
                            <p className="text-[10px] text-gray-500 truncate">
                              店鋪: {m.bookingDetail.salon}
                            </p>
                          </div>
                          <button
                            onClick={() => alert(`已成功驗證該預約明細：${m.bookingDetail?.date} 狀態完美。設計師已被引導並完成備料。`)}
                            className="w-full bg-white hover:bg-neutral-50 text-neutral-900 font-bold text-[10px] py-1.5 rounded-lg border border-amber-350 active:scale-95 transition-all cursor-pointer"
                          >
                            點選開啟明細詳情 📄
                          </button>
                        </div>
                      )}

                      {/* Designer structured Digital Price Quote Offers (Requirement: 報價卡片分享) */}
                      {m.isOffer && m.offerTitle && (
                        <div className="bg-slate-900 rounded-xl p-3 border border-slate-700 text-white mt-1 space-y-2.5 max-w-[210px]">
                          <div className="flex justify-between items-center pb-1 border-b border-slate-800">
                            <span className="text-[9px] text-amber-400 font-extrabold uppercase">設計師特惠提案</span>
                            <span className="text-[9px] bg-emerald-500/10 text-emerald-400 px-1.5 rounded font-mono font-bold">10% OFF</span>
                          </div>
                          <div className="space-y-0.5">
                            <p className="font-extrabold text-[11px] text-zinc-100 leading-normal">
                              {m.offerTitle}
                            </p>
                            <p className="text-[10px] text-zinc-400">含洗剪設計以及受損髮質修復精華</p>
                            <p className="font-mono font-extrabold text-sm text-yellow-400 mt-1">
                              特惠價: HK$ {m.offerPrice}
                            </p>
                          </div>
                          
                          {m.offerAccepted ? (
                            <div className="bg-zinc-800 text-emerald-400 font-extrabold text-[10px] py-2 rounded-lg flex items-center justify-center gap-1 text-center font-sans">
                              <CheckCircle2 className="w-3.5 h-3.5 stroke-[2.5]" />
                              <span>已接受報價與日程</span>
                            </div>
                          ) : (
                            <button
                              onClick={() => handleAcceptQuoteOffer(m.id)}
                              className="w-full bg-amber-400 hover:bg-amber-500 text-black font-extrabold text-[10px] py-2 rounded-lg active:scale-95 transition-all cursor-pointer shadow-xs"
                            >
                              同意並一鍵付款預約
                            </button>
                          )}
                        </div>
                      )}
                    </>
                  )}

                  {/* Message timestamp and check seen states representation */}
                  <div className="flex justify-end items-center gap-1 mt-1 shrink-0">
                    <span className={`text-[8px] font-sans ${isUser ? 'text-white/40' : 'text-gray-400'}`}>
                      {m.time}
                    </span>
                    {isUser && !m.isRecalled && (
                      <span className="shrink-0 leading-none">
                        {seenStatus[m.id] === 'seen' ? (
                          <div className="flex items-center gap-0.5 text-amber-400">
                            <span className="text-[8px] font-bold">已讀</span>
                            <CheckCheck className="w-2.5 h-2.5 stroke-[2.5]" />
                          </div>
                        ) : seenStatus[m.id] === 'delivered' ? (
                          <CheckCheck className="w-2.5 h-2.5 text-gray-500 opacity-60" />
                        ) : (
                          <Check className="w-2.5 h-2.5 text-gray-500 opacity-40" />
                        )}
                      </span>
                    )}
                  </div>
                </div>

                {/* USER ROW RECALL TRASH TRIGGER SHIFT (Requirement: 訊息撤回) */}
                {isUser && !m.isRecalled && (
                  <div className="opacity-0 group-hover:opacity-100 transition-opacity flex justify-end gap-1 px-1">
                    <button
                      onClick={() => handleRecallMessage(m.id)}
                      className="bg-red-50 text-red-600 hover:bg-red-100 p-1 px-2 text-[9px] rounded-full flex items-center gap-0.5 active:scale-95 cursor-pointer font-extrabold border border-red-200"
                      title="撤回此訊息"
                    >
                      <Trash2 className="w-2.5 h-2.5" />
                      <span>撤回</span>
                    </button>
                  </div>
                )}
              </div>
            </div>
          );
        })}

        {/* 💬 THREE-DOTS TYPING INDICATOR MODULE (Requirement: 正在輸入) */}
        {isTyping && (
          <div className="flex items-end gap-2 max-w-[80%]">
            <div className="w-8 h-8 rounded-full overflow-hidden shrink-0 border border-gray-150">
              <img src={stylist.avatar} alt="Agent typing" className="w-full h-full object-cover" />
            </div>
            <div className="bg-white p-3.5 px-4.5 rounded-2xl rounded-bl-none border border-gray-100 shadow-5xs text-gray-500 flex items-center gap-2">
              <span className="text-[10px] font-bold text-gray-400">{typingName} 正在輸入</span>
              <div className="flex gap-1">
                <span className="w-1.5 h-1.5 bg-neutral-900 rounded-full animate-bounce delay-100"></span>
                <span className="w-1.5 h-1.5 bg-neutral-900 rounded-full animate-bounce delay-200"></span>
                <span className="w-1.5 h-1.5 bg-neutral-900 rounded-full animate-bounce delay-300"></span>
              </div>
            </div>
          </div>
        )}

        <div className="bg-amber-50/70 border border-amber-200/50 p-3.5 rounded-xl flex items-start gap-2.5 shadow-5xs">
          <Info className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
          <div className="space-y-0.5">
            <h3 className="font-bold text-xs text-amber-900 tracking-tight">髮型師諮詢提示 Box</h3>
            <p className="text-[10px] text-gray-500 font-normal leading-relaxed">
              點擊下方的「＋」圖案，可直接分享推薦的精緻髮型照片、分享已有行程的「預約明細卡片」或索取專屬折扣數位「報價單」。
            </p>
          </div>
        </div>

        <div ref={chatBottomRef} />
      </main>

      {/* ➕ ATTACHMENT MULTIMEDIA DOCK DRAWER (Hairstyles search, mock selector, items share) */}
      {showAttachments && (
        <section className="bg-white border-t border-gray-150 p-4 space-y-4 shadow-md shrink-0 animate-slide-up max-h-[290px] overflow-y-auto no-scrollbar z-20">
          <div className="flex justify-between items-center pb-2 border-b border-gray-100">
            <span className="text-xs font-black text-neutral-900 uppercase tracking-wider">📦 髮型參考與快速沙龍分享工具箱</span>
            <button 
              onClick={() => setShowAttachments(false)}
              className="p-1 hover:bg-slate-100 rounded-full cursor-pointer transition-all"
            >
              <X className="w-4 h-4 text-gray-500" />
            </button>
          </div>

          {/* Quick share actions triggers */}
          <div className="grid grid-cols-3 gap-2.5 pb-1">
            <button
              onClick={shareUpcomingBookingCard}
              className="p-2.5 bg-slate-50 hover:bg-slate-100 rounded-xl border border-gray-150/60 flex flex-col items-center justify-center gap-1.5 text-center cursor-pointer transition-all active:scale-95"
            >
              <Calendar className="w-5 h-5 text-indigo-600 shrink-0" />
              <span className="text-[9px] font-black leading-tight text-gray-800">分享預約明細</span>
            </button>

            <button
              onClick={shareStylistPriceQuotations}
              className="p-2.5 bg-slate-50 hover:bg-slate-100 rounded-xl border border-gray-150/60 flex flex-col items-center justify-center gap-1.5 text-center cursor-pointer transition-all active:scale-95"
            >
              <DollarSign className="w-5 h-5 text-emerald-600 shrink-0" />
              <span className="text-[9px] font-black leading-tight text-gray-800">索取專屬報價單</span>
            </button>

            <button
              onClick={() => {
                const genericText = `📆 [系統安全須知] - 本交易受 AI Studio 平台支付條約全面保護中。如有不信任第三方，可及時使用檢舉功能存證。`;
                handleSendMessage(genericText, { isSystemAdvice: true });
                setShowAttachments(false);
              }}
              className="p-2.5 bg-slate-50 hover:bg-slate-100 rounded-xl border border-gray-150/60 flex flex-col items-center justify-center gap-1.5 text-center cursor-pointer transition-all active:scale-95"
            >
              <ShieldAlert className="w-5 h-5 text-red-500 shrink-0" />
              <span className="text-[9px] font-black leading-tight text-gray-800">發佈安全備註</span>
            </button>
          </div>

          {/* Preset Hairstyles selector section (Hairstyles photo share) */}
          <div className="space-y-2">
            <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">🖼️ 挑選沙龍熱門作品 (一鍵發送至對話)</p>
            <div className="flex gap-2 overflow-x-auto no-scrollbar py-0.5">
              {PRESET_HAIRSTYLES.map((hair) => (
                <div
                  key={hair.id}
                  onClick={() => shareHairstylePhoto(hair.title, hair.url)}
                  className="bg-slate-50 min-w-[120px] max-w-[120px] rounded-xl overflow-hidden border border-gray-150 cursor-pointer hover:border-black transition-all shadow-5xs shrink-0"
                >
                  <img src={hair.url} alt={hair.title} className="w-full h-18 object-cover" />
                  <div className="p-1.5">
                    <p className="text-[9px] font-extrabold text-gray-800 truncate leading-tight">{hair.title}</p>
                    <p className="text-[8px] text-gray-400 mt-0.5 font-semibold">設計: {hair.r}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Preset Hair Condition uploads selector (Photo upload reference) */}
          <div className="space-y-2 pt-1 border-t border-gray-50">
            <p className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">👩‍🦰 選擇個人「模擬髮況」上傳諮詢</p>
            <div className="flex gap-2 overflow-x-auto no-scrollbar py-0.5">
              {PRESET_USER_HAIRS.map((hair) => (
                <div
                  key={hair.id}
                  onClick={() => shareMyHairState(hair.title, hair.url)}
                  className="bg-slate-50 min-w-[120px] max-w-[120px] rounded-xl overflow-hidden border border-gray-100 hover:border-black cursor-pointer transition-all shadow-5xs shrink-0"
                >
                  <img src={hair.url} alt={hair.title} className="w-full h-18 object-cover" />
                  <div className="p-1.5">
                    <p className="text-[9px] font-extrabold text-gray-800 truncate leading-tight">{hair.title}</p>
                    <p className="text-[8px] text-red-600 truncate mt-0.5 font-mono">{hair.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* 🎹 LOWER CONSOLE MESSAGE INPUT BAR */}
      <section className="bg-white px-5 py-3 border-t border-gray-100 shrink-0 z-10 pb-6 relative">
        <div className="flex items-center gap-3">
          
          {/* Quick attachment toggles button */}
          <button
            onClick={() => {
              if (isBlocked[activeStylistId]) {
                alert('請先解除封鎖此設計師。');
                return;
              }
              setShowAttachments(!showAttachments);
            }}
            title="開啟髮型/預約分享工具箱"
            className={`flex flex-col items-center justify-center w-12 h-12 rounded-xl border transition-all active:scale-95 cursor-pointer shrink-0 ${
              showAttachments 
                ? 'bg-neutral-900 border-neutral-900 text-amber-400' 
                : 'bg-amber-100 text-amber-900 border-amber-200/60 hover:bg-amber-200'
            }`}
          >
            <Camera className="w-[18px] h-[18px]" />
          </button>

          {/* Typing field */}
          <div className="flex-1 relative flex items-center min-w-0">
            <input
              type="text"
              value={inputText}
              disabled={isBlocked[activeStylistId]}
              onChange={(e) => setInputText(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSendMessage(inputText)}
              className={`w-full bg-slate-50 border border-gray-200 focus:border-black focus:ring-0 rounded-full px-5 py-3.5 pr-10 text-xs placeholder-gray-400 disabled:bg-gray-100 disabled:text-gray-400`}
              placeholder={isBlocked[activeStylistId] ? '🚫 您已封鎖此設計師。解除後通話' : '發送對話訊息或敲入關鍵字 "價/燙/漂"...'}
            />
            <button 
              onClick={() => alert('已啟用顏文字表情鍵盤！')}
              className="absolute right-3.5 text-gray-400 hover:text-black transition-colors cursor-pointer"
            >
              <Smile className="w-4 h-4 shrink-0" />
            </button>
          </div>

          {/* Paper airplane trigger button */}
          <button
            onClick={() => handleSendMessage(inputText)}
            className="bg-black hover:bg-neutral-800 text-white w-12 h-12 rounded-full flex items-center justify-center active:scale-95 transition-all shadow-md cursor-pointer shrink-0"
          >
            <Send className="w-[16px] h-[16px] text-white shrink-0 ml-0.5" />
          </button>
        </div>
      </section>

      {/* ⚠️ DIALOG MODAL LAYOUT FOR REPORTING (Requirement: 舉報功能) */}
      {showReportModal && (
        <div className="fixed inset-0 bg-black/60 z-55 flex items-center justify-center p-5 animate-fade-in">
          <div className="bg-white rounded-3xl p-5 max-w-sm w-full space-y-4 shadow-2xl border border-gray-100 transform scale-100 transition-transform">
            <div className="flex justify-between items-start">
              <div className="text-amber-800 flex items-center gap-1.5">
                <AlertTriangle className="w-5 h-5" />
                <h3 className="font-extrabold text-base text-gray-900 font-sans tracking-tight">舉報設計師與不當內容</h3>
              </div>
              <button 
                onClick={() => setShowReportModal(false)}
                className="p-1 hover:bg-gray-100 rounded-full cursor-pointer transition-colors"
                type="button"
              >
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>

            <p className="text-[11px] text-gray-400 leading-normal font-sans">
              AI Studio 官方高度重視用戶隱私與不合理亂行。上傳證件聊天記錄將被作為稽查證據，檢舉流程完全匿名加密。
            </p>

            <form onSubmit={handleSubmitReport} className="space-y-4">
              
              {/* Select Reason category */}
              <div className="space-y-1.5 text-xs">
                <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">檢舉違規類別</label>
                <select
                  value={reportReason}
                  onChange={(e) => setReportReason(e.target.value)}
                  className="w-full bg-slate-50 border border-gray-200 rounded-xl p-2.5 font-bold focus:outline-none focus:ring-1 focus:ring-black"
                >
                  <option value="harassment">言語騷擾、態度惡劣 (Harassment)</option>
                  <option value="spam">違規廣告、導流非官方支付管道 (Redirect/Pay)</option>
                  <option value="fake">抄襲他人作品、虛假虛造年資 (Plagiarism)</option>
                  <option value="overprice">現場臨時高價增額、坐地起價 (Overcharging)</option>
                </select>
              </div>

              {/* Written explanation comment */}
              <div className="space-y-1.5 text-xs">
                <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">舉報詳細描述 (選填)</label>
                <textarea
                  rows={3}
                  placeholder="請提供事情經過細節，例如：對方誘導跳轉到 WhatsApp 線下付款、漫天叫價等..."
                  value={reportComment}
                  onChange={(e) => setReportComment(e.target.value)}
                  className="w-full bg-slate-50 border border-gray-200 rounded-xl p-2.5 text-xs focus:ring-1 focus:ring-black focus:outline-none placeholder-gray-400"
                />
              </div>

              {/* Action row buttons */}
              <div className="flex gap-2 pt-2 text-xs">
                <button
                  type="button"
                  onClick={() => setShowReportModal(false)}
                  className="flex-1 bg-slate-100 hover:bg-slate-200 text-gray-700 py-3 rounded-xl font-bold transition-all transition-colors cursor-pointer text-center"
                >
                  取消
                </button>
                <button
                  type="submit"
                  className="flex-1 bg-red-600 hover:bg-red-700 text-white py-3 rounded-xl font-bold transition-all transition-colors cursor-pointer text-center shadow-sm"
                >
                  提交匿名舉報
                </button>
              </div>

            </form>
          </div>
        </div>
      )}

    </div>
  );
}
