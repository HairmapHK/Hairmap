import React, { useState, useEffect } from 'react';
import { salonsData, stylistsData } from '../data';
import { 
  Star, Share2, ArrowLeft, MapPin, Clock, Phone, User, MessageCircle, Check, Sparkles 
} from 'lucide-react';
import { Review, Salon } from '../types';

interface SalonProfileProps {
  salonId?: string;
  onBack: () => void;
  onSelectStylist: (id: string) => void;
}

// Initial mock reviews database for salons mapped by id
const INITIAL_SALON_REVIEWS: Record<string, Review[]> = {
  's1': [
    {
      id: 'sr1_1',
      reviewerName: 'Natalie Wong',
      reviewerAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=120&q=80',
      text: '這家沙龍就在海港城，位置非常方便！裝潢高檔優雅，洗髮時的客製化精油香味令人超級放鬆。Leo 設計師的畫染技術好到沒話說，大家都讚不絕口！',
      stars: 5,
      timeAgo: '2 天前'
    },
    {
      id: 'sr1_2',
      reviewerName: 'Vincent Mok',
      reviewerAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&q=80',
      text: '整體的服務水平高，前台很熱心解答。染髮過程細心，沒有任何不適，極力推薦！',
      stars: 5,
      timeAgo: '1 週前'
    }
  ],
  's2': [
    {
      id: 'sr2_1',
      reviewerName: 'Ivan Cheung',
      reviewerAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&q=80',
      text: 'IFC 的黃金地段，高端大氣之選。Noir Studio 的店面燈光與工業音樂氛圍超級讚，Alex 對細節的追求近乎完美，油頭推剪非常有深度。',
      stars: 5,
      timeAgo: '3 天前'
    },
    {
      id: 'sr2_2',
      reviewerName: 'Winnie Tse',
      reviewerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=120&q=80',
      text: '剪髮服務流暢，環境精緻，雖然人比較多需要提前一週預約，但技術確實比一般沙龍高一檔。',
      stars: 4,
      timeAgo: '5 天前'
    }
  ],
  's3': [
    {
      id: 'sr3_1',
      reviewerName: 'Christy Leung',
      reviewerAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=120&q=80',
      text: '在銅鑼灣時代廣場，很適合血拼完直接過來做造型。店內空間寬敞又注重顧客隱私，Sarah 做的韓式捲度超級唯美，Q彈不僵硬，會一直回購。',
      stars: 5,
      timeAgo: '1 天前'
    }
  ],
  's4': [
    {
      id: 'sr4_1',
      reviewerName: 'Danny Choy',
      reviewerAvatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=120&q=80',
      text: 'Mong Kok 首選的時尚中心！Jessica 的縮毛矯正拯救了我的自然捲稻草，做完之後一整個月都不容易扁塌，店員態度都非常溫柔有禮！',
      stars: 5,
      timeAgo: '4 天前'
    }
  ]
};

// Map salons to their respective in-shop stylists for hyper-realistic connection
const SALON_STYLISTS_MAP: Record<string, string[]> = {
  's1': ['master-leo'],
  's2': ['alex-chen'],
  's3': ['sarah-lin'],
  's4': ['jessica-ho']
};

export default function SalonProfile({ salonId = 's1', onBack, onSelectStylist }: SalonProfileProps) {
  const salon = salonsData.find(s => s.id === salonId) || salonsData[0];
  
  // State to hold reviews locally to support user interactions
  const [reviewsList, setReviewsList] = useState<Review[]>([]);
  
  // Review posting form state
  const [inputName, setInputName] = useState('');
  const [inputText, setInputText] = useState('');
  const [selectedStars, setSelectedStars] = useState(5);
  const [formError, setFormError] = useState('');

  // Settle reviews list whenever salonId changes
  useEffect(() => {
    const defaultReviews = INITIAL_SALON_REVIEWS[salon.id] || [];
    setReviewsList(defaultReviews);
    // Reset form
    setInputName('');
    setInputText('');
    setSelectedStars(5);
    setFormError('');
  }, [salon.id, salon]);

  // Find stylists associated with this salon
  const stylistIdsOfSalon = SALON_STYLISTS_MAP[salon.id] || ['master-leo'];
  const salonStylists = stylistsData.filter(sty => stylistIdsOfSalon.includes(sty.id));

  // Handle review form submission
  const handleSubmitReview = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim()) {
      setFormError('請填寫一些評價內容！');
      return;
    }
    setFormError('');

    const newReview: Review = {
      id: `sr_user_${Date.now()}`,
      reviewerName: inputName.trim() || '熱心顧客',
      reviewerAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=120&q=80', // generic premium portrait
      text: inputText.trim(),
      stars: selectedStars,
      timeAgo: '剛剛發表'
    };

    setReviewsList(prev => [newReview, ...prev]);
    alert('🎉 感謝您的評價！您的寶貴回饋已新增至本沙龍，且沙龍評分已即時計算更新。');
    
    // Clear form inputs
    setInputName('');
    setInputText('');
    setSelectedStars(5);
  };

  // Dynamically calculate average rating based on local reviews
  const displayRating = reviewsList.length > 0 
    ? (reviewsList.reduce((sum, r) => sum + r.stars, 0) / reviewsList.length).toFixed(1)
    : salon.rating.toFixed(1);

  return (
    <div className="w-full h-full bg-slate-50 text-gray-900 flex flex-col relative overflow-hidden select-none">
      
      {/* Top Sticky App Bar with blur effect */}
      <header className="w-full z-45 bg-white bg-white/95 backdrop-blur-md flex justify-between items-center px-5 py-3.5 border-b border-gray-100/80 shadow-2xs shrink-0">
        <button
          onClick={onBack}
          className="active:scale-95 duration-150 p-2 hover:bg-gray-100 rounded-full cursor-pointer transition-all shrink-0"
        >
          <ArrowLeft className="w-5 h-5 text-black" />
        </button>
        <span className="font-serif font-bold text-xl text-black truncate max-w-[65%]">沙龍檔案詳情</span>
        <button
          onClick={() => alert(`已複製「${salon.name}」沙龍專屬連結至您的剪貼簿！`)}
          className="active:scale-95 duration-150 p-2 hover:bg-gray-100 rounded-full cursor-pointer transition-all shrink-0"
        >
          <Share2 className="w-5 h-5 text-black" />
        </button>
      </header>

      <div className="flex-1 overflow-y-auto no-scrollbar pb-40 relative">
        {/* Salon Big Representative Cover */}
      <section className="relative w-full h-[280px] overflow-hidden shrink-0">
        <img
          alt={`${salon.name} Cover`}
          className="w-full h-full object-cover brightness-95"
          src={salon.imageUrl}
          referrerPolicy="no-referrer"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-slate-950/85 via-slate-900/35 to-transparent flex flex-col justify-end p-5">
          <div className="flex flex-wrap gap-1 mb-1.5">
            {salon.tags.map((tag) => (
              <span key={tag} className="bg-amber-400 text-black text-[9px] font-extrabold px-2 py-0.5 rounded-sm shadow-xs uppercase">
                #{tag}
              </span>
            ))}
          </div>
          <h1 className="font-sans text-2xl font-bold text-white mb-1 tracking-tight">{salon.name}</h1>
          <div className="flex items-center gap-1.5 text-xs text-neutral-300">
            <MapPin className="w-3.5 h-3.5 text-amber-400 shrink-0" />
            <span className="truncate">{salon.location} (距離您大約 {salon.distance} 公里)</span>
          </div>
        </div>
      </section>

      {/* Overlapping Quick Core Info Card */}
      <section className="px-5 -mt-5 relative z-10">
        <div className="bg-white rounded-2xl shadow-md p-4.5 flex justify-between items-center border border-gray-100">
          <div className="text-center flex-1 border-r border-gray-100">
            <div className="flex items-center justify-center gap-0.5 mb-0.5">
              <Star className="w-4 h-4 fill-amber-400 text-amber-400" />
              <span className="font-bold text-sm text-gray-900">{displayRating}</span>
            </div>
            <p className="text-[10px] text-gray-400 font-bold uppercase tracking-wider">評分 ({reviewsList.length} 則)</p>
          </div>
          <div className="text-center flex-1 border-r border-gray-100">
            <p className="font-bold text-xs text-gray-900 mb-1 flex items-center justify-center gap-1">
              <Clock className="w-3.5 h-3.5 text-gray-400" />
              <span>{salon.openHours}</span>
            </p>
            <p className="text-[10px] text-gray-400 font-bold uppercase tracking-wider">營業時間</p>
          </div>
          <div className="text-center flex-1">
            <p className="font-bold text-xs text-gray-900 mb-1 flex items-center justify-center gap-1">
              <Phone className="w-3.5 h-3.5 text-gray-400" />
              <span>{salon.phone}</span>
            </p>
            <p className="text-[10px] text-gray-400 font-bold uppercase tracking-wider">聯絡與諮詢</p>
          </div>
        </div>
      </section>

      {/* Salon Introduction Info */}
      <section className="mt-6 px-5 space-y-2">
        <h2 className="font-bold text-base text-gray-900 font-sans tracking-tight">沙龍優勢與特徵 Info</h2>
        <div className="bg-white rounded-2xl p-4 border border-gray-100 space-y-3 shadow-3xs">
          <p className="text-xs text-gray-600 leading-relaxed font-sans">
            歡迎光臨 <strong className="text-gray-950 font-bold">{salon.name}</strong>！我們店內空間皆經過精緻簡約規劃，為每位尊貴顧客提供舒適無壓的洗浴、按摩及造型時光。全店均採用日本及義大利進口頂級有機染護專利產品。
          </p>
          <div className="flex flex-wrap gap-1 text-[10px] text-gray-500 font-semibold">
            <span className="bg-slate-100 rounded px-2.5 py-1">✓ 免費進口氣泡水/手沖咖啡</span>
            <span className="bg-slate-100 rounded px-2.5 py-1">✓ 專屬充電插座與千兆 Wi-Fi</span>
            <span className="bg-slate-100 rounded px-2.5 py-1">✓ 頭皮敏感隔離修護與香氛紓壓</span>
          </div>
        </div>
      </section>

      {/* IN-SALON STYLISTS LIST - Click is fully supported */}
      <section className="mt-8 px-5">
        <h2 className="font-bold text-base text-gray-900 font-sans tracking-tight mb-3.5 flex items-center gap-1.5">
          <Sparkles className="w-4.5 h-4.5 text-amber-500" />
          <span>本沙龍精選「駐店設計師」</span>
        </h2>
        <div className="grid grid-cols-1 gap-3">
          {salonStylists.map((sty) => (
            <div
              key={sty.id}
              onClick={() => onSelectStylist(sty.id)}
              className="bg-white p-3.5 rounded-xl border border-gray-100 hover:border-amber-300 shadow-3xs hover:shadow-sm transition-all duration-350 cursor-pointer flex items-center justify-between group"
            >
              <div className="flex items-center gap-3.5">
                <div className="w-12 h-12 rounded-full overflow-hidden border border-gray-150 shrink-0">
                  <img
                    alt={sty.name}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    src={sty.avatar}
                    referrerPolicy="no-referrer"
                  />
                </div>
                <div className="space-y-1">
                  <h3 className="font-bold text-sm text-gray-900 group-hover:text-amber-800 transition-colors">
                    {sty.name}
                  </h3>
                  <p className="text-[11px] text-gray-400 font-medium">
                    {sty.title} • {sty.experience}年資歷
                  </p>
                  <p className="text-[10px] bg-slate-50 text-slate-600 px-2 py-0.5 rounded inline-block font-semibold">
                    專長: {sty.specialties.join(' ')}
                  </p>
                </div>
              </div>
              <div className="flex flex-col items-end shrink-0 pl-1.5 justify-center">
                <div className="flex items-center gap-0.5 bg-amber-50 rounded px-1.5 py-0.5 border border-amber-150 text-[11px] font-bold text-amber-800 mb-1">
                  <Star className="w-3 h-3 fill-amber-500 text-amber-500" />
                  <span>{sty.rating}</span>
                </div>
                <span className="text-[10px] text-gray-400 hover:underline font-semibold block uppercase">查看個人檔案 →</span>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Salon Portfolio (Pre-seeded with works) */}
      <section className="mt-8 px-5">
        <h2 className="font-bold text-base text-gray-900 font-sans tracking-tight mb-3">沙龍最新作品展示</h2>
        <div className="grid grid-cols-2 gap-3 pb-2">
          {salonStylists.flatMap(sty => sty.works).slice(0, 4).map((work) => (
            <div key={work.id} className="relative rounded-xl overflow-hidden aspect-square border border-gray-100 shadow-3xs group cursor-pointer bg-slate-100">
              <img
                alt={work.title}
                className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-103"
                src={work.imageUrl}
                referrerPolicy="no-referrer"
              />
              <div className="absolute inset-x-0 bottom-0 p-2 bg-gradient-to-t from-black/80 via-black/35 to-transparent">
                <p className="text-[11px] font-bold text-white truncate">{work.title}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Salon Services Start Price info section */}
      <section className="mt-8 px-5">
        <h2 className="font-bold text-base text-gray-900 font-sans tracking-tight mb-3">沙龍精選定價項目</h2>
        <div className="bg-white rounded-2xl p-4 border border-gray-100 shadow-3xs space-y-3.5">
          <div className="flex justify-between items-center text-xs pb-2 border-b border-gray-50 text-gray-700">
            <span>精緻洗髮剪裁 (包含吹風修飾造型)</span>
            <span className="font-extrabold text-gray-950">HK$ {salon.startPrice} 起</span>
          </div>
          <div className="flex justify-between items-center text-xs pb-2 border-b border-gray-50 text-gray-700">
            <span>頂級有機無損染髮 (含染前隔離與受損修復)</span>
            <span className="font-extrabold text-gray-950">HK$ {Math.round(salon.startPrice * 1.5)} 起</span>
          </div>
          <div className="flex justify-between items-center text-xs text-gray-700">
            <span>韓式層次氣墊澎潤燙 / 精緻縮毛矯正</span>
            <span className="font-extrabold text-gray-950">HK$ {Math.round(salon.startPrice * 1.8)} 起</span>
          </div>
        </div>
      </section>

      {/* Customer Reviews for Salon with Review Writing Module */}
      <section className="mt-8 px-5 tracking-tight space-y-5">
        <div className="flex justify-between items-center">
          <h2 className="font-bold text-base text-gray-900 font-sans tracking-tight">顧客評價 Reviews</h2>
          <span className="text-xs bg-amber-50 text-amber-800 border border-amber-200 font-bold px-2.5 py-0.5 rounded-full">
            平均 {displayRating} 星
          </span>
        </div>

        {/* Existing reviews list */}
        <div className="space-y-3.5">
          {reviewsList.map((review) => (
            <div key={review.id} className="bg-white p-4 rounded-xl shadow-3xs border border-gray-100">
              <div className="flex justify-between items-start mb-2.5">
                <div className="flex items-center gap-2.5">
                  <div className="w-9 h-9 rounded-full overflow-hidden border border-gray-150 shrink-0">
                    <img
                      alt={review.reviewerName}
                      className="w-full h-full object-cover"
                      src={review.reviewerAvatar}
                      referrerPolicy="no-referrer"
                    />
                  </div>
                  <div>
                    <span className="font-bold text-xs text-gray-900 block">{review.reviewerName}</span>
                    <span className="text-[10px] text-gray-400 block font-semibold">{review.timeAgo}</span>
                  </div>
                </div>
                <div className="flex text-amber-400 gap-0.5">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <Star
                      key={i}
                      className={`w-3 h-3 ${i < review.stars ? 'fill-amber-400 text-amber-400' : 'text-gray-200'}`}
                    />
                  ))}
                </div>
              </div>
              <p className="text-xs text-gray-600 leading-relaxed font-normal">{review.text}</p>
            </div>
          ))}
        </div>

        {/* WRITE REVIEW FORM - User request 2 */}
        <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm space-y-4">
          <div className="flex items-center gap-1.5 pb-2 border-b border-gray-50">
            <span className="text-sm font-bold text-gray-900">✍️ 發表您的真實優質評價</span>
          </div>

          <form onSubmit={handleSubmitReview} className="space-y-3.5">
            {/* Input name */}
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">您的稱呼</label>
              <input
                type="text"
                placeholder="例如: Winnie, Alex, (留空則化名發表)"
                value={inputName}
                onChange={(e) => setInputName(e.target.value)}
                className="w-full bg-slate-50 border border-gray-150 rounded-xl p-2.5 text-xs focus:ring-1 focus:ring-black focus:border-black focus:outline-none"
              />
            </div>

            {/* Interactive Stars Selector */}
            <div className="space-y-1.5">
              <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">評分等級</label>
              <div className="flex gap-1.5 p-1">
                {Array.from({ length: 5 }).map((_, idx) => {
                  const starVal = idx + 1;
                  const isSelected = selectedStars >= starVal;
                  return (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => setSelectedStars(starVal)}
                      className="transition-transform active:scale-90 p-1 bg-transparent border-none cursor-pointer"
                    >
                      <Star
                        className={`w-5 h-5 ${
                          isSelected ? 'fill-amber-400 text-amber-400' : 'text-gray-200'
                        }`}
                      />
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Write comment */}
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">評價心得內容 (必填)</label>
              <textarea
                rows={3}
                required
                placeholder="分享您的剪髮、諮詢或環境享受等真實體驗心得..."
                value={inputText}
                onChange={(e) => setInputText(e.target.value)}
                className="w-full bg-slate-50 border border-gray-150 rounded-xl p-2.5 text-xs max-h-24 focus:ring-1 focus:ring-black focus:border-black focus:outline-none placeholder-gray-400"
              />
            </div>

            {formError && (
              <p className="text-[11px] font-bold text-red-500">{formError}</p>
            )}

            <button
              type="submit"
              className="w-full bg-neutral-900 text-white hover:bg-neutral-800 font-bold text-xs py-3 rounded-xl transition-all active:scale-[0.98] cursor-pointer shadow-2xs"
            >
              送出並發佈沙龍評價
            </button>
          </form>
        </div>

      </section>

      </div>

      {/* Floating consult button */}
      <button
        onClick={() => alert(`已撥號致電 ${salon.phone} 進行沙龍預約諮詢！`)}
        className="absolute bottom-28 right-5 w-14 h-14 bg-amber-400 hover:bg-amber-500 shadow-xl rounded-full flex items-center justify-center text-black z-40 hover:scale-105 active:scale-95 transition-all border border-amber-300 cursor-pointer"
        title="電話預約/諮詢"
      >
        <Phone className="w-5 h-5 shrink-0" />
      </button>

      {/* Floating button footer indicator */}
      <div className="absolute bottom-0 left-0 w-full bg-white/95 backdrop-blur-xl px-5 py-4 flex items-center justify-between z-45 shadow-[0_-8px_24px_rgba(0,0,0,0.03)] border-t border-gray-100">
        <div className="space-y-0.5">
          <p className="text-[10px] text-gray-400 font-bold uppercase tracking-wider">店家起價</p>
          <p className="font-bold text-lg text-gray-900">HK$ {salon.startPrice}</p>
        </div>
        <button
          onClick={() => {
            if (salonStylists.length > 0) {
              onSelectStylist(salonStylists[0].id);
            } else {
              onSelectStylist('master-leo');
            }
          }}
          className="bg-black text-white hover:bg-neutral-800 p-3.5 px-6 rounded-xl font-bold text-xs inline-flex items-center gap-1.5 transition-all active:scale-95 cursor-pointer shadow-sm"
        >
          <span>選擇駐店設計師預約</span>
          <ArrowLeft className="w-4 h-4 rotate-180" />
        </button>
      </div>

    </div>
  );
}
