import React, { useState } from 'react';
import { inspirationFeed, salonsData } from '../data';
import { 
  Heart, Search, SlidersHorizontal, ArrowRight, Plus, X, 
  Upload, Camera, Check, Tag, Info, Calendar, Sparkles 
} from 'lucide-react';

interface InspirationProps {
  onSelectStylist: (stylistId: string) => void;
  onSelectSalon?: (salonId: string) => void;
}

interface FeedItem {
  id: string;
  title: string;
  salon: string;
  location: string;
  tags: string[];
  imageUrl: string;
  category: '熱門趨勢' | '關注中' | '最新髮型';
  likesCount?: number;
  description?: string;
  suitableFace?: string;
  suitableHair?: string;
  maintenance?: string;
  creatorName?: string;
}

// Enhance the imported static feed with rich details
const ENHANCED_INITIAL_FEED: FeedItem[] = inspirationFeed.map((item, idx) => {
  const descriptions = [
    "超人氣高層次蓬鬆燙，能完美修飾雙頰線條，出門前只需隨興抓鬆即可，非常適合追求慵懶隨性風格的您！",
    "利用精細的手刷染技術，交織出落日琥珀般的溫暖層次。即使黑髮長出來也不會突兀，是歐美風格的熱門首選！",
    "經典帥氣漸層油頭，分線乾淨俐落。強烈推薦給渴望清爽、同時展現雅痞格調的男士。",
    "經典法式包伯剪，髮尾內彎弧度恰到好處，顯臉小且具知性氣質，不論日常或出席正式場合都非常得體。"
  ];
  const suitableFaces = [
    "圓臉、鵝蛋臉、菱形臉",
    "心形臉、高顴骨臉型、方形臉",
    "所有臉型、特別修飾方臉",
    "長臉、鵝蛋臉、倒三角臉"
  ];
  const suitableHairs = [
    "細軟髮或一般髮質、中等髮量",
    "粗硬髮或中等受損髮質、中至多髮量",
    "一般髮質、粗硬髮質、任何髮量",
    "細軟髮、一般髮質、髮量適中"
  ];
  const maintenances = [
    "洗髮後抹上輕感乳液，由下往上烘乾即可維持立體蓬鬆感。",
    "建議使用護色洗髮精，避免陽光過度曝曬以維持精緻的暖色光澤。",
    "洗髮後吹乾，使用微濕感髮泥或髮膠，向後梳整即可塑型。",
    "使用大圓梳搭配吹風機向內順吹，或使用離子夾稍微順整髮尾。"
  ];

  return {
    ...item,
    category: item.category as '熱門趨勢' | '關注中' | '最新髮型',
    likesCount: 12 + (idx * 7),
    description: descriptions[idx % descriptions.length],
    suitableFace: suitableFaces[idx % suitableFaces.length],
    suitableHair: suitableHairs[idx % suitableHairs.length],
    maintenance: maintenances[idx % maintenances.length],
    creatorName: "Master Leo"
  };
});

// Gorgeous Unsplash Preset Hair Images for instant simulation
const PRESET_MOCK_IMAGES = [
  {
    name: '日系復古羊毛卷',
    url: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=600&q=80',
    tags: ['日系羊毛卷', '復古捲度', '蓬鬆感']
  },
  {
    name: '巴黎冷色手刷染',
    url: 'https://images.unsplash.com/photo-1595959183075-c1d0a174db24?auto=format&fit=crop&w=600&q=80',
    tags: ['巴黎挑染', '灰亞麻色', '漸層手刷']
  },
  {
    name: '法式柔霧鮑伯',
    url: 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=600&q=80',
    tags: ['法式鮑伯', '柔霧茶色', '輕盈剪裁']
  }
];

export default function Inspiration({ onSelectStylist, onSelectSalon }: InspirationProps) {
  const [activeTab, setActiveTab] = useState<'熱門趨勢' | '關注中' | '最新髮型'>('熱門趨勢');
  const [feedList, setFeedList] = useState<FeedItem[]>(ENHANCED_INITIAL_FEED);
  const [likedFeeds, setLikedFeeds] = useState<Record<string, boolean>>({});
  
  // Modal toggle states
  const [selectedFeed, setSelectedFeed] = useState<FeedItem | null>(null);
  const [showUploadModal, setShowUploadModal] = useState(false);

  // New Post Form State
  const [uploadImgUrl, setUploadImgUrl] = useState('');
  const [selectedPresetIdx, setSelectedPresetIdx] = useState<number | null>(null);
  const [newTitle, setNewTitle] = useState('');
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [customTag, setCustomTag] = useState('');
  const [newSuitableFace, setNewSuitableFace] = useState('鵝蛋臉、圓臉皆適合');
  const [newSuitableHair, setNewSuitableHair] = useState('一般髮質、中等或細軟髮量');
  const [newMaintenance, setNewMaintenance] = useState('整理非常簡單，吹乾後抹上少許免沖洗護髮油即可。');
  const [newDescription, setNewDescription] = useState('');
  const [uploadFileError, setUploadFileError] = useState('');

  // Suggested Tags list
  const suggestedTags = ['日系羊毛卷', '巴黎挑染', '縮毛矯正', '裙擺染', '高層次氣墊燙', '經典漸層油頭', '線條感挑染'];

  const handleLike = (e: React.MouseEvent, id: string) => {
    e.stopPropagation();
    const isCurrentlyLiked = !!likedFeeds[id];
    
    setLikedFeeds((prev) => ({
      ...prev,
      [id]: !isCurrentlyLiked
    }));

    setFeedList(prevList => 
      prevList.map(item => {
        if (item.id === id) {
          return {
            ...item,
            likesCount: (item.likesCount || 0) + (isCurrentlyLiked ? -1 : 1)
          };
        }
        return item;
      })
    );
  };

  // Handle local File upload
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        setUploadFileError('照片檔案過大，請選擇小於 5MB 的檔案');
        return;
      }
      setUploadFileError('');
      const reader = new FileReader();
      reader.onloadend = () => {
        setUploadImgUrl(reader.result as string);
        setSelectedPresetIdx(null); // clear preset selection
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSelectPreset = (idx: number) => {
    setSelectedPresetIdx(idx);
    setUploadImgUrl(PRESET_MOCK_IMAGES[idx].url);
    if (!newTitle) {
      setNewTitle(PRESET_MOCK_IMAGES[idx].name);
    }
    // autopopulate tags
    const presetTags = PRESET_MOCK_IMAGES[idx].tags;
    setSelectedTags(prev => {
      const combined = new Set([...prev, ...presetTags]);
      return Array.from(combined);
    });
  };

  const handleToggleTag = (tag: string) => {
    if (selectedTags.includes(tag)) {
      setSelectedTags(prev => prev.filter(t => t !== tag));
    } else {
      setSelectedTags(prev => [...prev, tag]);
    }
  };

  const handleAddCustomTag = () => {
    const trimmed = customTag.trim();
    if (trimmed && !selectedTags.includes(trimmed)) {
      setSelectedTags(prev => [...prev, trimmed]);
      setCustomTag('');
    }
  };

  const handleSubmitPost = (e: React.FormEvent) => {
    e.preventDefault();
    if (!uploadImgUrl) {
      setUploadFileError('請選擇上傳照片或選擇一個精美預設範本');
      return;
    }
    if (!newTitle.trim()) {
      alert('請為您的髮型分享填寫一個標題！');
      return;
    }

    const newFeedItem: FeedItem = {
      id: 'feed_new_' + Date.now(),
      title: newTitle.trim(),
      salon: "Alex 的個人分享",
      location: "香港 · 銅鑼灣",
      tags: selectedTags.length > 0 ? selectedTags : ['最新潮流'],
      imageUrl: uploadImgUrl,
      category: '最新髮型',
      likesCount: 1,
      description: newDescription.trim() || '這是我在 Hairmap 最新預約體驗的精緻髮型，剪完質感大幅提升，大力推薦給大家！',
      suitableFace: newSuitableFace,
      suitableHair: newSuitableHair,
      maintenance: newMaintenance,
      creatorName: 'Alex Chen (您本人)'
    };

    setFeedList(prev => [newFeedItem, ...prev]);
    alert('🎉 發布成功！您的髮型已成功分享，並列入「最新髮型」與「熱門趨勢」探索牆中。');
    
    // Reset fields and close
    setShowUploadModal(false);
    setUploadImgUrl('');
    setSelectedPresetIdx(null);
    setNewTitle('');
    setSelectedTags([]);
    setNewDescription('');
    setActiveTab('最新髮型'); // Switch to let user see their post immediately!
  };

  return (
    <div className="w-full h-full bg-[#fcfcfc] text-gray-900 overflow-y-auto no-scrollbar pb-28 relative">
      
      {/* Top App Bar inside main container */}
      <header className="bg-white/90 backdrop-blur-md w-full sticky top-0 z-40 transition-all duration-300 border-b border-gray-100/80 shadow-xs">
        <div className="flex justify-between items-center px-5 py-4 w-full">
          <button className="text-gray-500 hover:text-black transition-opacity active:scale-95 cursor-pointer">
            <Search className="w-5 h-5" />
          </button>
          <div className="flex items-center gap-1.5">
            <Sparkles className="w-5 h-5 text-amber-500 fill-amber-300" />
            <h1 className="font-serif text-2xl font-bold tracking-tight text-neutral-950">髮型靈感探索</h1>
          </div>
          <button className="text-gray-500 hover:text-black transition-opacity active:scale-95 cursor-pointer">
            <SlidersHorizontal className="w-5 h-5" />
          </button>
        </div>
      </header>

      {/* Hero Invitation / Community Stats info block */}
      <div className="m-5 mt-4 p-5 rounded-2xl bg-gradient-to-br from-neutral-900 to-neutral-800 text-white shadow-md relative overflow-hidden">
        <div className="absolute top-0 right-0 w-32 h-32 bg-amber-400 opacity-10 rounded-full blur-2xl transform translate-x-10 -translate-y-10"></div>
        <div className="relative z-10 space-y-1">
          <span className="text-[10px] bg-amber-400 text-neutral-900 font-extrabold uppercase px-2 py-0.5 rounded tracking-wider">NEW FUNCTION</span>
          <h2 className="font-bold text-lg text-white mt-1">秀出您的完美新髮型！</h2>
          <p className="text-xs text-neutral-300 leading-normal max-w-[85%] font-light">
            剛剪好帥氣或溫柔的髮型嗎？立即上傳分享，啟發有著相同尋覓想法的其他使用者，還能標記您的設計師喔！
          </p>
          <button 
            onClick={() => setShowUploadModal(true)}
            className="mt-3 bg-white text-black font-bold text-xs py-2 px-4 rounded-xl shadow-sm hover:bg-amber-100 transition-colors active:scale-95 cursor-pointer inline-flex items-center gap-1.5"
          >
            <Plus className="w-3.5 h-3.5 text-black stroke-[3]" />
            <span>立即上傳分享我的髮型</span>
          </button>
        </div>
      </div>

      {/* Magazine Style tabs */}
      <div className="sticky top-[60px] bg-white/95 backdrop-blur-md z-30 px-5 pt-3 pb-3 border-b border-gray-100 flex items-center justify-between shadow-2xs">
        <div className="flex gap-5 overflow-x-auto no-scrollbar items-end">
          {(['熱門趨勢', '最新髮型', '關注中'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`pb-1 border-b-2 font-bold text-sm whitespace-nowrap transition-all duration-300 cursor-pointer ${
                activeTab === tab 
                  ? 'border-neutral-950 text-neutral-950 scale-102' 
                  : 'border-transparent text-gray-400 hover:text-black'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>
        
        <button 
          onClick={() => setShowUploadModal(true)} 
          className="text-xs text-white bg-black hover:bg-neutral-800 font-bold px-3 py-1.5 rounded-lg flex items-center gap-1 shadow-xs cursor-pointer active:scale-95 transition-all"
        >
          <Plus className="w-3.5 h-3.5 text-white" />
          <span>上傳</span>
        </button>
      </div>

      {/* Masonry-like Custom Grid container */}
      <div className="px-5 pt-4">
        {feedList.length > 0 ? (
          <div className="grid grid-cols-2 gap-4">
            {feedList
              .filter(item => activeTab === '熱門趨勢' || (activeTab === '最新髮型' && item.category === '最新髮型') || activeTab === '關注中')
              .map((item) => {
                const isLiked = !!likedFeeds[item.id];
                
                return (
                  <div
                    key={item.id}
                    onClick={() => setSelectedFeed(item)}
                    className="flex flex-col rounded-2xl bg-white shadow-2xs border border-gray-100 overflow-hidden hover:shadow-md hover:-translate-y-0.5 transition-all duration-300 cursor-pointer group"
                  >
                    {/* Hair Visual Container */}
                    <div className="aspect-[3/4] relative overflow-hidden bg-gray-100 shrink-0">
                      <img
                        alt={item.title}
                        className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
                        src={item.imageUrl}
                        referrerPolicy="no-referrer"
                      />
                      
                      {/* Likes Counter Layer */}
                      <div className="absolute bottom-2 left-2 bg-black/50 backdrop-blur-xs text-white font-mono text-[9px] font-bold px-2 py-0.5 rounded-full flex items-center gap-1">
                        <Heart className="w-2.5 h-2.5 fill-red-500 text-red-500" />
                        <span>{item.likesCount || 0}</span>
                      </div>

                      {/* Favorite bubble toggle */}
                      <button
                        onClick={(e) => handleLike(e, item.id)}
                        className="absolute top-2 right-2 bg-white/90 backdrop-blur-xs p-1.5 rounded-full text-black hover:bg-emerald-50 transition-all hover:scale-110 active:scale-95 cursor-pointer shadow-sm"
                      >
                        <Heart
                          className={`w-[15px] h-[15px] transition-colors ${
                            isLiked ? 'fill-red-500 text-red-500 animate-bounce' : 'text-gray-600'
                          }`}
                        />
                      </button>
                    </div>

                    {/* Brief description content */}
                    <div className="p-3 flex-1 flex flex-col justify-between">
                      <div className="space-y-1">
                        <h3 className="font-bold text-xs text-gray-900 leading-snug group-hover:text-amber-800 transition-colors line-clamp-1">{item.title}</h3>
                        <p className="text-[10px] text-gray-400 font-medium truncate">{item.salon}</p>
                      </div>

                      {/* Small elegant list tags tags */}
                      <div className="flex flex-wrap gap-1 mt-2 pt-1 border-t border-gray-50">
                        {item.tags.slice(0, 2).map((t) => (
                          <span key={t} className="text-[9px] font-semibold text-neutral-600 bg-neutral-100 px-1.5 py-0.5 rounded">
                            #{t}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>
                );
              })}
          </div>
        ) : (
          <div className="text-center py-16 text-gray-400">
            <p className="text-sm">這個分類暫時沒有內容，點擊右上方上傳加入吧！</p>
          </div>
        )}
      </div>

      {/* Floating Upload Trigger Trigger Bubble Button */}
      <button
        onClick={() => setShowUploadModal(true)}
        className="fixed bottom-20 right-5 z-40 bg-neutral-950 text-white hover:bg-neutral-800 p-4 rounded-full shadow-lg hover:shadow-amber-900/10 transition-all active:scale-95 cursor-pointer flex items-center justify-center border border-neutral-800"
        title="分享我的髮型範本"
      >
        <Plus className="w-6 h-6 text-white stroke-[2.5]" />
      </button>

      {/* -------------------- DETAIL OVERLAY DIALOG -------------------- */}
      {selectedFeed && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-end md:items-center justify-center p-0 md:p-6 animate-fade-in animate-duration-200">
          <div className="bg-white w-full max-w-md h-[90vh] md:h-auto md:max-h-[85vh] rounded-t-[32px] md:rounded-[24px] overflow-hidden flex flex-col shadow-2xl relative">
            
            {/* Top Close bar */}
            <div className="absolute top-4 right-4 z-55">
              <button
                onClick={() => setSelectedFeed(null)}
                className="bg-black/60 backdrop-blur-md text-white hover:bg-black/90 p-2.5 rounded-full transition-all cursor-pointer shadow-md"
              >
                <X className="w-5 h-5 text-white" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto no-scrollbar">
              {/* Full bleed image layout */}
              <div className="w-full aspect-[4/5] bg-gray-100 relative">
                <img
                  alt={selectedFeed.title}
                  className="w-full h-full object-cover"
                  src={selectedFeed.imageUrl}
                  referrerPolicy="no-referrer"
                />
                
                {/* Visual Cover mask overlay gradient */}
                <div className="absolute inset-x-0 bottom-0 h-28 bg-gradient-to-t from-black/80 via-black/40 to-transparent"></div>
                
                {/* Core title badge header overlays */}
                <div className="absolute bottom-4 left-5 right-5 text-white space-y-1">
                  <span className="text-[10px] bg-amber-400 text-black font-bold uppercase tracking-wider px-2 py-0.5 rounded shadow">
                    熱門靈感範本
                  </span>
                  <h2 className="font-bold text-xl drop-shadow tracking-tight">{selectedFeed.title}</h2>
                  <p className="text-xs text-neutral-200 font-light truncate">
                    由 {selectedFeed.creatorName || "設計師"} 分享於 {selectedFeed.salon}
                  </p>
                </div>
              </div>

              {/* Hairstyle detail information wrapper */}
              <div className="p-5 space-y-6">
                
                {/* Interactive Action Stats tags */}
                <div className="flex items-center justify-between p-3.5 bg-neutral-50 rounded-2xl border border-neutral-100">
                  <div className="flex items-center gap-1.5 text-neutral-800">
                    <Heart className="w-5 h-5 text-red-500 fill-red-500" />
                    <span className="font-bold font-mono text-sm">{selectedFeed.likesCount || 10} 個人說讚</span>
                  </div>
                  <button 
                    onClick={(e) => {
                      handleLike(e, selectedFeed.id);
                    }}
                    className={`text-xs p-2 px-4 rounded-xl font-bold cursor-pointer transition-all border ${
                      likedFeeds[selectedFeed.id] 
                        ? 'bg-rose-50 text-rose-600 border-rose-200' 
                        : 'bg-white text-gray-800 border-gray-200 hover:bg-neutral-100'
                    }`}
                  >
                    {likedFeeds[selectedFeed.id] ? '已點讚❤️' : '點擊點讚'}
                  </button>
                </div>

                {/* Tag pills */}
                <div className="space-y-2">
                  <p className="text-[10px] text-gray-400 font-bold uppercase tracking-wider flex items-center gap-1">
                    <Tag className="w-3 h-3 text-gray-400" />
                    <span>髮型設計標籤</span>
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {selectedFeed.tags.map((tag) => (
                      <span 
                        key={tag}
                        className="text-xs font-bold bg-amber-50 text-amber-900 border border-amber-200/40 px-3.5 py-1 rounded-full cursor-pointer hover:bg-amber-150 transition-colors"
                      >
                        #{tag}
                      </span>
                    ))}
                  </div>
                </div>

                {/* Stylist comment / Description text */}
                <div className="space-y-2">
                  <p className="text-[10px] text-gray-400 font-bold uppercase tracking-wider">造型亮點與說明 Highlights</p>
                  <p className="text-sm font-normal leading-relaxed text-gray-700 font-sans">
                    {selectedFeed.description}
                  </p>
                </div>

                {/* Detailed Spec Card list sheets */}
                <div className="space-y-3 bg-neutral-50 rounded-2xl p-4.5 border border-neutral-100">
                  <h3 className="text-xs font-bold text-neutral-800 mb-3 uppercase tracking-wider flex items-center gap-1">
                    <Info className="w-4 h-4 text-amber-600" />
                    <span>髮型細節適配評估</span>
                  </h3>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-1">
                      <p className="text-[10px] text-gray-400 font-semibold uppercase">適配臉型</p>
                      <p className="text-xs font-bold text-gray-800 leading-tight">{selectedFeed.suitableFace || "大部分臉型皆適配"}</p>
                    </div>
                    <div className="space-y-1">
                      <p className="text-[10px] text-gray-400 font-semibold uppercase">適配髮質</p>
                      <p className="text-xs font-bold text-gray-800 leading-tight">{selectedFeed.suitableHair || "一般至硬性髮質皆可"}</p>
                    </div>
                  </div>

                  <div className="pt-3 border-t border-neutral-200/50 mt-1 space-y-1">
                    <p className="text-[10px] text-gray-400 font-semibold uppercase">設計師黃金整理技巧</p>
                    <p className="text-xs text-neutral-600 font-normal leading-relaxed">{selectedFeed.maintenance || "洗後順著方向吹整即可。"}</p>
                  </div>
                </div>

                {/* Simulated Location & Salon info cards */}
                <section className="bg-amber-50/40 p-4 rounded-xl border border-amber-100 flex items-center justify-between">
                  <div>
                    <h4 className="font-semibold text-xs text-amber-900">推薦此沙龍/設計師</h4>
                    <p className="text-[11px] text-gray-500 mt-1">{selectedFeed.salon} ({selectedFeed.location})</p>
                  </div>
                  <button
                    onClick={() => {
                      const matchedSalon = salonsData.find(s => s.name.toLowerCase().includes(selectedFeed.salon.toLowerCase()) || selectedFeed.salon.toLowerCase().includes(s.name.toLowerCase())) || salonsData[0];
                      setSelectedFeed(null);
                      if (onSelectSalon) {
                        onSelectSalon(matchedSalon.id);
                      }
                    }}
                    className="bg-neutral-900 hover:bg-neutral-800 text-white font-bold text-xs py-2 px-3 rounded-lg flex items-center gap-1 shadow-xs transition-colors cursor-pointer"
                  >
                    <span>沙龍詳情</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </button>
                </section>
              </div>
            </div>

            {/* Sticky Actions in Modal bottom */}
            <div className="p-4 border-t border-gray-100/80 bg-white/95 sticky bottom-0 inset-x-0 w-full flex gap-3">
              <button 
                onClick={() => setSelectedFeed(null)}
                className="flex-1 h-12 rounded-xl text-xs font-bold border border-gray-200 text-gray-800 hover:bg-gray-50 cursor-pointer transition-all active:scale-98"
              >
                關閉視窗
              </button>
              <button
                onClick={() => {
                  const stylistMap: Record<string, string> = {
                    'Maison de Beauté': 'master-leo',
                    'Noir Studio': 'alex-chen',
                    'Zenith Premium Salon': 'sarah-lin',
                    'Elysian Hair Art': 'jessica-ho'
                  };
                  const stylistId = stylistMap[selectedFeed.salon] || 'master-leo';
                  setSelectedFeed(null);
                  onSelectStylist(stylistId);
                }}
                className="flex-2 h-12 bg-black text-white hover:bg-neutral-800 rounded-xl text-xs font-bold flex items-center justify-center gap-1 shadow-md transition-all active:scale-98 cursor-pointer"
              >
                <span>立即預約此款髮型設計師</span>
                <ArrowRight className="w-4 h-4 text-white" />
              </button>
            </div>
          </div>
        </div>
      )}


      {/* -------------------- UPLOAD NEW POST MODAL -------------------- */}
      {showUploadModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-end justify-center p-0 md:p-6 animate-fade-in">
          <div className="bg-white w-full max-w-md h-[92vh] rounded-t-[32px] overflow-hidden flex flex-col shadow-2xl relative">
            
            {/* Header static sticky */}
            <header className="p-5 border-b border-gray-100 flex justify-between items-center bg-white shrink-0">
              <div className="flex items-center gap-1.5">
                <Camera className="w-5 h-5 text-neutral-800" />
                <h3 className="font-bold text-lg text-neutral-900 font-sans">分享我的新髮型</h3>
              </div>
              <button
                onClick={() => setShowUploadModal(false)}
                className="p-1 px-2.5 rounded-full hover:bg-gray-150 text-gray-500 hover:text-black font-semibold text-xs cursor-pointer transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </header>

            {/* Scrollable form controls */}
            <form onSubmit={handleSubmitPost} className="flex-1 overflow-y-auto p-5 space-y-6 no-scrollbar pb-32">
              
              {/* Photo Area Choice selector */}
              <div className="space-y-3">
                <label className="text-[11px] font-bold text-gray-400 uppercase tracking-widest block">
                  選擇照片 (可手動上傳或按預設精美展示)
                </label>

                {/* Standard file picker input wrapper drag simulator */}
                <div className="grid grid-cols-2 gap-3">
                  <label className="border-2 border-dashed border-gray-200 hover:border-black rounded-2xl p-5 flex flex-col items-center justify-center text-center bg-gray-50/50 hover:bg-neutral-100 transition-all cursor-pointer min-h-[140px]">
                    <Upload className="w-6 h-6 text-gray-400 mb-2 shrink-0" />
                    <span className="text-xs font-bold text-gray-800">上傳手機照片</span>
                    <span className="text-[9px] text-gray-400 mt-1 leading-normal font-medium">支援隨拍相機 / 圖庫</span>
                    <input 
                      type="file" 
                      accept="image/*" 
                      onChange={handleFileChange} 
                      className="hidden" 
                    />
                  </label>

                  {/* Chosen Image Display frame preview */}
                  <div className="border border-gray-150 rounded-2xl relative overflow-hidden flex items-center justify-center bg-gray-100 min-h-[140px]">
                    {uploadImgUrl ? (
                      <div className="w-full h-full relative group">
                        <img 
                          alt="Uploaded avatar draft" 
                          src={uploadImgUrl} 
                          className="w-full h-full object-cover" 
                        />
                        <button
                          type="button"
                          onClick={() => {
                            setUploadImgUrl('');
                            setSelectedPresetIdx(null);
                          }}
                          className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-xs font-bold transition-opacity"
                        >
                          更換照片
                        </button>
                      </div>
                    ) : (
                      <div className="text-center p-3 text-gray-400">
                        <p className="text-[10px] font-semibold">隨選預設範例或點左側上傳</p>
                      </div>
                    )}
                  </div>
                </div>

                {uploadFileError && (
                  <p className="text-xs text-rose-500 font-semibold">{uploadFileError}</p>
                )}

                {/* Elegant Presets selector to ease quick trials */}
                <div className="space-y-1.5 pt-1">
                  <p className="text-[10px] text-gray-400 font-bold uppercase tracking-wider">
                    ⚡ 快速模擬：熱門髮型照片範本
                  </p>
                  <div className="grid grid-cols-3 gap-2">
                    {PRESET_MOCK_IMAGES.map((item, idx) => {
                      const isSelected = selectedPresetIdx === idx;
                      return (
                        <button
                          key={idx}
                          type="button"
                          onClick={() => handleSelectPreset(idx)}
                          className={`border p-1 rounded-xl text-center flex flex-col justify-between overflow-hidden cursor-pointer transition-all ${
                            isSelected 
                              ? 'border-amber-400 bg-amber-50 ring-2 ring-amber-400' 
                              : 'border-gray-200 hover:bg-gray-50 bg-white'
                          }`}
                        >
                          <div className="h-10 w-full overflow-hidden rounded-lg bg-gray-100 shrink-0">
                            <img alt={item.name} src={item.url} className="w-full h-full object-cover" />
                          </div>
                          <span className="text-[9px] font-bold text-gray-800 truncate block mt-1 leading-none">{item.name}</span>
                        </button>
                      );
                    })}
                  </div>
                </div>
              </div>

              {/* Title Form control */}
              <div className="space-y-1.5">
                <label className="text-[11px] font-bold text-gray-400 uppercase tracking-widest block">
                  髮型分享標題 Title
                </label>
                <input
                  type="text"
                  required
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  className="w-full bg-gray-50 border border-gray-150 rounded-xl p-3 text-sm focus:outline-none focus:ring-1 focus:ring-black focus:border-black"
                  placeholder="例如：巴黎手刷染歐美畫染挑染、氣質空氣瀏海"
                />
              </div>

              {/* Category tags selector */}
              <div className="space-y-2">
                <label className="text-[11px] font-bold text-gray-400 uppercase tracking-widest block">
                  標記您的髮型特點 (可多選)
                </label>

                {/* Predeclared list */}
                <div className="flex flex-wrap gap-1.5">
                  {suggestedTags.map((tag) => {
                    const isSelected = selectedTags.includes(tag);
                    return (
                      <button
                        key={tag}
                        type="button"
                        onClick={() => handleToggleTag(tag)}
                        className={`text-[11px] font-semibold px-3 py-1.5 rounded-full border transition-all cursor-pointer ${
                          isSelected 
                            ? 'bg-black text-white border-black shadow-xs' 
                            : 'bg-white text-gray-600 border-gray-200 hover:bg-neutral-50'
                        }`}
                      >
                        #{tag}
                      </button>
                    );
                  })}
                </div>

                {/* Custom tags append */}
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={customTag}
                    onChange={(e) => setCustomTag(e.target.value)}
                    className="flex-1 bg-gray-50 border border-gray-150 rounded-xl p-2.5 text-xs focus:ring-1 focus:ring-black focus:border-black"
                    placeholder="輸入自訂標籤 (例如: 日系小狼尾)"
                  />
                  <button
                    type="button"
                    onClick={handleAddCustomTag}
                    className="text-xs bg-gray-150 hover:bg-gray-200 font-bold px-4 rounded-xl cursor-pointer"
                  >
                    加入
                  </button>
                </div>
              </div>

              {/* Suitable Specifications fields */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-[11px] font-bold text-gray-400 uppercase tracking-widest block">
                    適配臉型
                  </label>
                  <input
                    type="text"
                    value={newSuitableFace}
                    onChange={(e) => setNewSuitableFace(e.target.value)}
                    className="w-full bg-gray-50 border border-gray-150 rounded-xl p-3 text-xs"
                    placeholder="圓臉、心形臉、橢圓臉"
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-[11px] font-bold text-gray-400 uppercase tracking-widest block">
                    適配髮質
                  </label>
                  <input
                    type="text"
                    value={newSuitableHair}
                    onChange={(e) => setNewSuitableHair(e.target.value)}
                    className="w-full bg-gray-50 border border-gray-150 rounded-xl p-3 text-xs"
                    placeholder="一般至粗硬、多髮量"
                  />
                </div>
              </div>

              {/* Maintenance tips */}
              <div className="space-y-1.5">
                <label className="text-[11px] font-bold text-gray-400 uppercase tracking-widest block">
                  日常保養與整理技巧 Specs
                </label>
                <input
                  type="text"
                  value={newMaintenance}
                  onChange={(e) => setNewMaintenance(e.target.value)}
                  className="w-full bg-gray-50 border border-gray-150 rounded-xl p-3 text-xs"
                  placeholder="吹風機順吹，兩天抹一次精華護髮"
                />
              </div>

              {/* Descriptions area */}
              <div className="space-y-1.5">
                <label className="text-[11px] font-bold text-gray-400 uppercase tracking-widest block">
                  心得說明與推薦 Details
                </label>
                <textarea
                  value={newDescription}
                  onChange={(e) => setNewDescription(e.target.value)}
                  rows={3}
                  className="w-full bg-gray-50 border border-gray-150 rounded-xl p-3 text-xs max-h-32 focus:ring-1 focus:ring-black"
                  placeholder="跟大家分享這個髮型您最喜歡的地方，或者整理保養心得呢！"
                />
              </div>

              {/* Form Bottom Submission controls overlay fixed inside slide */}
              <div className="fixed bottom-0 left-0 w-full bg-white p-4 flex gap-4 border-t border-gray-150 md:relative md:bg-transparent md:border-none md:p-0 md:pt-4">
                <button
                  type="button"
                  onClick={() => setShowUploadModal(false)}
                  className="flex-1 h-12 rounded-xl text-xs font-bold border border-gray-250 text-gray-800 hover:bg-gray-50 cursor-pointer active:scale-[0.98] transition-all"
                >
                  取消
                </button>
                <button
                  type="submit"
                  className="flex-1 h-12 bg-black text-white hover:bg-neutral-800 rounded-xl text-xs font-bold shadow-md cursor-pointer active:scale-[0.98] transition-all"
                >
                  確認發布分享
                </button>
              </div>

            </form>
          </div>
        </div>
      )}

    </div>
  );
}
