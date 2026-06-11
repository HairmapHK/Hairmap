import React, { useState } from 'react';
import { stylistsData } from '../data';
import { Star, Share2, ArrowLeft, Plus, Check, MessageCircle, Calendar } from 'lucide-react';
import { Service } from '../types';

interface StylistProfileProps {
  stylistId?: string;
  onBack: () => void;
  onBook: (selectedService: Service | null) => void;
  onChat: () => void;
}

export default function StylistProfile({ stylistId = 'master-leo', onBack, onBook, onChat }: StylistProfileProps) {
  const stylist = stylistsData.find((s) => s.id === stylistId) || stylistsData[0];
  
  // Choose default preselected services depending on designer
  const defaultPreselected = stylist.services[0]?.id || 's_color';
  const [selectedServices, setSelectedServices] = useState<Record<string, boolean>>({
    [defaultPreselected]: true
  });

  // Local state to keep track of added reviews
  const [reviewsList, setReviewsList] = useState<any[]>([]);
  const [inputName, setInputName] = useState('');
  const [inputText, setInputText] = useState('');
  const [selectedStars, setSelectedStars] = useState(5);
  const [formError, setFormError] = useState('');

  // Sync when stylist changes
  React.useEffect(() => {
    setReviewsList(stylist.reviews || []);
    setInputName('');
    setInputText('');
    setSelectedStars(5);
    setFormError('');
  }, [stylist.id, stylist]);

  const toggleService = (id: string) => {
    setSelectedServices(prev => ({
      ...prev,
      [id]: !prev[id]
    }));
  };

  // Calculate selected total price
  const totalPrice = stylist.services.reduce((total, service) => {
    if (selectedServices[service.id]) {
      return total + service.price;
    }
    return total;
  }, 0);

  const getFirstSelectedService = (): Service | null => {
    const selectedKeys = Object.keys(selectedServices).filter(key => selectedServices[key]);
    if (selectedKeys.length === 0) return null;
    const found = stylist.services.find(s => s.id === selectedKeys[0]);
    return found || null;
  };

  return (
    <div className="w-full h-full bg-slate-50 text-gray-900 flex flex-col relative overflow-hidden select-none">
      {/* Top sticky app bar with backdrop blur */}
      <header className="w-full z-45 bg-white/95 backdrop-blur-md flex justify-between items-center px-5 py-3 border-b border-gray-100 shrink-0">
        <button
          onClick={onBack}
          className="active:scale-95 duration-150 p-2 hover:bg-gray-100 rounded-full cursor-pointer transition-all"
        >
          <ArrowLeft className="w-5 h-5 text-black" />
        </button>
        <span className="font-serif font-bold text-xl text-black">Hairmap</span>
        <button
          onClick={() => alert('已複製分享檔案連結！')}
          className="active:scale-95 duration-150 p-2 hover:bg-gray-100 rounded-full cursor-pointer transition-all"
        >
          <Share2 className="w-5 h-5 text-black" />
        </button>
      </header>

      <div className="flex-1 overflow-y-auto no-scrollbar pb-40 relative">
        {/* Hero Profile Banner with bottom overlay gradient */}
      <section className="relative w-full h-[320px] overflow-hidden shrink-0">
        <img
          alt={`${stylist.name} Profile`}
          className="w-full h-full object-cover grayscale-[5%] sepia-[2%] brightness-85"
          src={stylist.avatar}
          referrerPolicy="no-referrer"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-slate-900/90 via-slate-900/30 to-transparent flex flex-col justify-end p-5 pb-8">
          <h1 className="font-serif text-3xl font-bold text-white mb-2">{stylist.name}</h1>
          <div className="flex flex-wrap gap-2">
            {stylist.specialties.map((spec) => (
              <span
                key={spec}
                className="bg-white/20 backdrop-blur-md text-white px-3.5 py-1 rounded-full text-xs font-semibold border border-white/30"
              >
                {spec}
              </span>
            ))}
          </div>
        </div>
      </section>

      {/* Stats overlapping summary box */}
      <section className="px-5 -mt-6 relative z-10">
        <div className="bg-white rounded-2xl shadow-lg p-5 flex justify-between items-center border border-gray-100/50">
          <div className="text-center flex-1 border-r border-gray-100">
            <div className="flex items-center justify-center gap-1 mb-1">
              <Star className="w-4 h-4 fill-amber-400 text-amber-400" />
              <span className="font-bold text-sm text-gray-900">{stylist.rating}</span>
            </div>
            <p className="text-[10px] text-gray-400 font-semibold tracking-wider uppercase">評分</p>
          </div>
          <div className="text-center flex-1 border-r border-gray-100">
            <p className="font-bold text-sm text-gray-900 mb-1">{stylist.experience}</p>
            <p className="text-[10px] text-gray-400 font-semibold tracking-wider uppercase">資歷</p>
          </div>
          <div className="text-center flex-1">
            <p className="font-bold text-sm text-gray-900 mb-1">{stylist.languages}</p>
            <p className="text-[10px] text-gray-400 font-semibold tracking-wider uppercase">語言</p>
          </div>
        </div>
      </section>

      {/* Portfolio Gallery carousel */}
      <section className="mt-8">
        <div className="px-5 flex justify-between items-end mb-4">
          <h2 className="font-bold text-lg text-gray-900">作品集</h2>
          <button className="text-amber-800 text-sm font-semibold hover:underline bg-transparent border-none cursor-pointer">
            查看全部
          </button>
        </div>
        <div className="flex overflow-x-auto gap-4 px-5 no-scrollbar pb-2">
          {stylist.works.map((work) => (
            <div key={work.id} className="min-w-[220px] max-w-[220px] group cursor-pointer">
              <div className="aspect-[3/4] rounded-xl overflow-hidden mb-2 shadow-xs border border-gray-100">
                <img
                  alt={work.title}
                  className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                  src={work.imageUrl}
                  referrerPolicy="no-referrer"
                />
              </div>
              <p className="font-semibold text-sm text-gray-800 tracking-tight">{work.title}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Services List with interactive checklists */}
      <section className="mt-8 px-5">
        <h2 className="font-bold text-lg text-gray-900 mb-4">服務項目</h2>
        <div className="space-y-4">
          {stylist.services.map((service) => {
            const isSelected = !!selectedServices[service.id];
            return (
              <div
                key={service.id}
                className="flex justify-between items-center py-4 border-b border-gray-100 transition-all"
              >
                <div className="flex-1 pr-4">
                  <h3 className="font-bold text-sm text-gray-900">{service.name}</h3>
                  <p className="text-xs text-gray-500 mt-1">{service.description}</p>
                </div>
                <div className="flex items-center gap-4">
                  <span className="font-bold text-lg text-gray-900">${service.price}</span>
                  <button
                    onClick={() => toggleService(service.id)}
                    className={`w-10 h-10 rounded-full flex items-center justify-center transition-all duration-300 active:scale-90 cursor-pointer ${
                      isSelected 
                        ? 'bg-black text-white hover:bg-neutral-800 border-none shadow-md' 
                        : 'border border-black hover:bg-neutral-50 text-black'
                    }`}
                  >
                    {isSelected ? <Check className="w-5 h-5" /> : <Plus className="w-5 h-5" />}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* Reviews Section */}
      <section className="mt-8 px-5">
        <div className="flex justify-between items-end mb-4">
          <h2 className="font-bold text-lg text-gray-900">顧客評價</h2>
          <button className="text-amber-800 text-sm font-semibold hover:underline bg-transparent border-none cursor-pointer">
            {reviewsList.length} 則評價
          </button>
        </div>
        <div className="space-y-4">
          {reviewsList.map((review) => (
            <div key={review.id} className="bg-white p-4 rounded-xl shadow-xs border border-gray-100">
              <div className="flex justify-between items-start mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full overflow-hidden border border-gray-100">
                    <img
                      alt={review.reviewerName}
                      src={review.reviewerAvatar}
                      referrerPolicy="no-referrer"
                    />
                  </div>
                  <div>
                    <p className="font-bold text-sm text-gray-900">{review.reviewerName}</p>
                    <p className="text-[10px] text-gray-400 mt-0.5">{review.timeAgo}</p>
                  </div>
                </div>
                <div className="flex text-amber-400">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <Star
                      key={i}
                      className={`w-3.5 h-3.5 ${
                        i < review.stars ? 'fill-amber-400 text-amber-400' : 'text-gray-250'
                      }`}
                    />
                  ))}
                </div>
              </div>
              <p className="text-xs text-gray-600 leading-relaxed font-normal mb-3">{review.text}</p>
              {review.images && review.images.length > 0 && (
                <div className="flex gap-2">
                  {review.images.map((imgUrl, idx) => (
                    <img
                      key={idx}
                      alt="Review sample"
                      className="w-20 h-20 rounded-lg object-cover border border-gray-100 shadow-2xs"
                      src={imgUrl}
                      referrerPolicy="no-referrer"
                    />
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>

        {/* WRITE STYLIST REVIEW FORM */}
        <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-3xs space-y-4 mt-6">
          <div className="flex items-center gap-1.5 pb-2 border-b border-gray-100">
            <span className="text-sm font-bold text-gray-900">✍️ 發表您對設計師的珍貴評價</span>
          </div>

          <form 
            onSubmit={(e) => {
              e.preventDefault();
              if (!inputText.trim()) {
                setFormError('請輸入您的真實評價！');
                return;
              }
              const newRev = {
                id: `rev_u_${Date.now()}`,
                reviewerName: inputName.trim() || '熱心顧客',
                reviewerAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=120&q=80',
                text: inputText.trim(),
                stars: selectedStars,
                timeAgo: '剛剛發表'
              };
              setReviewsList(prev => [newRev, ...prev]);
              alert('🎉 感謝您的評價！已為您發布此評論，設計師將會收到即時回饋通知。');
              setInputName('');
              setInputText('');
              setSelectedStars(5);
              setFormError('');
            }}
            className="space-y-3.5"
          >
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">您的稱呼</label>
              <input
                type="text"
                placeholder="例如: Alex, Winnie (留空則化名發表)"
                value={inputName}
                onChange={(e) => setInputName(e.target.value)}
                className="w-full bg-slate-50 border border-gray-150 rounded-xl p-2.5 text-xs focus:ring-1 focus:ring-black focus:border-black focus:outline-none"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">評分等級</label>
              <div className="flex gap-1.5 p-1">
                {Array.from({ length: 5 }).map((_, idx) => {
                  const val = idx + 1;
                  const isSelected = selectedStars >= val;
                  return (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => setSelectedStars(val)}
                      className="p-1 cursor-pointer transition-transform active:scale-95 bg-transparent border-none"
                    >
                      <Star className={`w-5 h-5 ${isSelected ? 'fill-amber-400 text-amber-400' : 'text-gray-200'}`} />
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="space-y-1">
              <label className="text-[10px] font-bold text-gray-400 uppercase tracking-wider block font-sans">評價說明內容 (必填)</label>
              <textarea
                required
                rows={3}
                placeholder="分享您在髮型微調、燙髮、漂染染髮過程中的心得..."
                value={inputText}
                onChange={(e) => setInputText(e.target.value)}
                className="w-full bg-slate-50 border border-gray-150 rounded-xl p-2.5 text-xs focus:ring-1 focus:ring-black focus:border-black focus:outline-none placeholder-gray-400"
              />
            </div>

            {formError && <p className="text-xs text-red-500 font-bold">{formError}</p>}

            <button
              type="submit"
              className="w-full bg-neutral-900 text-white hover:bg-neutral-800 font-bold text-xs py-3 rounded-xl transition-all active:scale-[0.95] cursor-pointer shadow-2xs"
            >
              送出並發表此設計師評價
            </button>
          </form>
        </div>
      </section>

      </div>

      {/* Floating Messenger trigger */}
      <button
        onClick={onChat}
        className="absolute bottom-28 right-6 w-14 h-14 bg-white hover:bg-neutral-50 shadow-xl rounded-full flex items-center justify-center text-black z-40 hover:scale-105 active:scale-95 transition-all border border-gray-200 cursor-pointer"
      >
        <MessageCircle className="w-6 h-6 shrink-0" />
      </button>

      {/* Bottom Sticky action-checkout bar */}
      <div className="absolute bottom-0 left-0 w-full bg-white/95 backdrop-blur-xl px-5 py-4 flex items-center justify-between z-45 shadow-[0_-8px_24px_rgba(0,0,0,0.04)] border-t border-gray-100">
        <div>
          <p className="text-[10px] text-gray-400 font-semibold uppercase tracking-wider">已選服務</p>
          <p className="font-bold text-xl text-gray-900">${totalPrice.toFixed(2)}</p>
        </div>
        <button
          onClick={() => onBook(getFirstSelectedService())}
          className="bg-amber-100 text-amber-900 border border-amber-200 hover:bg-amber-200 px-6 py-4 rounded-xl font-bold text-sm inline-flex items-center gap-2 transform active:scale-98 transition-all cursor-pointer shadow-xs"
        >
          <span>立即預約</span>
          <Calendar className="w-4 h-4 flex-shrink-0" />
        </button>
      </div>
    </div>
  );
}
