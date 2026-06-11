import React, { useState } from 'react';
import { ArrowLeft, Camera, User, MapPin, UploadCloud, Clock, PlusCircle, CalendarOff, BadgeDollarSign, Scissors, ShieldCheck, Mail, Phone, Link } from 'lucide-react';

interface StylistApplicationProps {
  onBack: () => void;
  onSubmitSuccess: () => void;
}

export default function StylistApplication({ onBack, onSubmitSuccess }: StylistApplicationProps) {
  const [step, setStep] = useState(1);
  const totalSteps = 6;

  // Form State
  const [avatar, setAvatar] = useState<string | null>(null);
  const [selectedSpots, setSelectedSpots] = useState<Record<string, boolean>>({
    '尖沙咀': true,
    '銅鑼灣': true
  });

  const spots = ['中環', '銅鑼灣', '尖沙咀', '旺角', '沙田', '荃灣'];

  const toggleSpot = (spot: string) => {
    setSelectedSpots((prev) => ({
      ...prev,
      [spot]: !prev[spot]
    }));
  };

  const handleNext = () => {
    if (step < totalSteps) {
      setStep((prev) => prev + 1);
    } else {
      alert('🌟 申請已成功提交！Hairmap 團隊將在 3 個工作天內審核您的個人履歷及作品集，並將以電話或 Email 聯繫您！感謝您的加入。');
      onSubmitSuccess();
    }
  };

  const handlePrev = () => {
    if (step > 1) {
      setStep((prev) => prev - 1);
    }
  };

  // Profile icon simulator
  const handlePortraitUpload = () => {
    setAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuCu_Du5MDrsjGbQCER4AfBOekSJT7RYGFxPh9Rncm93jQ6GCLA2lApJ6jKcHp5GQR3SG3KORkr9Iv_p6Twe_HTboWytRwfYczlsBhBdEgUdTDcYyGHYdBbwDltRswa45QONk4w6H23c31446NETuHYmaPhZbSj4jsE-jybWeVY2oPZsdYU6ZhnjGkiJjFyYGJhLHD7OZ0EJwgjlbHPVo7d4j_64sS5-COFKmII4jsqMzBNKrCVVxLbhbQTWMwg6ECfEaJ3VI6Mx77c');
  };

  return (
    <div className="w-full h-full bg-slate-50 text-gray-900 overflow-y-auto no-scrollbar pb-32 animate-fade-in">
      {/* Top Header bar */}
      <header className="bg-white sticky top-0 w-full z-50 border-b border-gray-100 flex justify-between items-center px-5 h-16">
        <div className="flex items-center gap-3">
          <button
            onClick={onBack}
            className="p-2 hover:bg-gray-100 rounded-full transition-all cursor-pointer text-black"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <span className="font-bold text-lg text-black tracking-tight font-sans">成為髮型師</span>
        </div>
        <div className="text-xs font-bold text-gray-400">
          第 {step} 步 / {totalSteps}
        </div>
      </header>

      <main className="max-w-md mx-auto px-5 pt-6 pb-12">
        {/* Step 1: Basic Info */}
        {step === 1 && (
          <div className="space-y-6 animate-fade-in">
            <h2 className="text-xl font-bold text-black font-sans">基本資料 (1/6)</h2>

            <div className="flex flex-col items-center">
              <div className="relative">
                <button
                  type="button"
                  onClick={handlePortraitUpload}
                  className="w-24 h-24 rounded-full bg-gray-100 flex items-center justify-center overflow-hidden border border-gray-200 cursor-pointer hover:bg-gray-200 transition-colors"
                >
                  {avatar ? (
                    <img alt="Portrait placeholder avatar" className="w-full h-full object-cover" src={avatar} referrerPolicy="no-referrer" />
                  ) : (
                    <Camera className="w-8 h-8 text-gray-400" />
                  )}
                </button>
                <span className="absolute bottom-0 right-0 bg-black text-white p-1.5 rounded-full shadow-md pointer-events-none">
                  <Camera className="w-3.5 h-3.5" />
                </span>
              </div>
              <p className="text-xs text-gray-400 font-semibold mt-3">上傳或模擬專業個人頭像</p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-gray-400">中文姓名</label>
                <input
                  type="text"
                  className="w-full bg-white border border-gray-200 focus:border-black focus:ring-0 rounded-lg p-3 text-sm"
                  placeholder="例如：陳大文"
                />
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-gray-400">英文姓名</label>
                <input
                  type="text"
                  className="w-full bg-white border border-gray-200 focus:border-black focus:ring-0 rounded-lg p-3 text-sm"
                  placeholder="例如：David Chan"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-gray-400">聯絡電話</label>
              <div className="flex items-center bg-white border border-gray-200 rounded-lg p-3">
                <Phone className="w-4 h-4 text-gray-400 mr-2 shrink-0" />
                <input
                  type="tel"
                  className="w-full bg-transparent border-none p-0 text-sm focus:outline-none focus:ring-0"
                  placeholder="例如：+852 9123 4567"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-gray-400">電子郵件</label>
              <div className="flex items-center bg-white border border-gray-200 rounded-lg p-3">
                <Mail className="w-4 h-4 text-gray-400 mr-2 shrink-0" />
                <input
                  type="email"
                  className="w-full bg-transparent border-none p-0 text-sm focus:outline-none focus:ring-0"
                  placeholder="name@example.com"
                />
              </div>
            </div>
          </div>
        )}

        {/* Step 2: Professional Info */}
        {step === 2 && (
          <div className="space-y-6 animate-fade-in">
            <h2 className="text-xl font-bold text-black font-sans">專業資歷 (2/6)</h2>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-gray-400">資歷年數</label>
              <select className="w-full bg-white border border-gray-200 focus:border-black focus:ring-0 rounded-lg p-3 text-sm">
                <option value="">請選擇資歷</option>
                <option>1-2 年</option>
                <option>3-5 年</option>
                <option>6-10 年</option>
                <option>10 年以上</option>
              </select>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-gray-400">現職職位</label>
              <select className="w-full bg-white border border-gray-200 focus:border-black focus:ring-0 rounded-lg p-3 text-sm">
                <option value="">請選擇職稱</option>
                <option>Junior Stylist 初級髮型師</option>
                <option>Senior Stylist 高級髮型師</option>
                <option>Master Stylist 首席髮型師</option>
                <option>Artistic Director 藝術總監</option>
              </select>
            </div>

            <div className="space-y-3">
              <label className="text-xs font-semibold text-gray-400">擅長剪裁項目 (可多選)</label>
              <div className="grid grid-cols-2 gap-3">
                {['男士剪髮', '女士剪髮', '染髮設計', '電髮造型', '護理療程', '新娘造型'].map((item) => (
                  <label key={item} className="flex items-center gap-2 p-3.5 rounded-lg border border-gray-200 bg-white cursor-pointer hover:bg-gray-50 transition-colors">
                    <input type="checkbox" className="rounded text-black focus:ring-black" />
                    <span className="text-xs font-semibold text-gray-700">{item}</span>
                  </label>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Step 3: Work Location */}
        {step === 3 && (
          <div className="space-y-6 animate-fade-in">
            <h2 className="text-xl font-bold text-black font-sans">工作地點 (3/6)</h2>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-gray-400">任職髮廊名稱</label>
              <div className="flex items-center bg-white border border-gray-200 rounded-lg p-3">
                <MapPin className="w-4 h-4 text-gray-400 mr-2 shrink-0" />
                <input
                  type="text"
                  className="w-full bg-transparent border-none p-0 text-sm focus:outline-none focus:ring-0"
                  placeholder="輸入任職沙龍名稱"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-gray-400">沙龍地址</label>
              <input
                type="text"
                className="w-full bg-white border border-gray-200 focus:border-black focus:ring-0 rounded-lg p-3 text-sm"
                placeholder="街道、大廈品牌及門牌樓層"
              />
            </div>

            <div className="space-y-3">
              <label className="text-xs font-semibold text-gray-400">服務重點區域 (可多選)</label>
              <div className="flex flex-wrap gap-2">
                {spots.map((spot) => {
                  const active = !!selectedSpots[spot];
                  return (
                    <button
                      key={spot}
                      type="button"
                      onClick={() => toggleSpot(spot)}
                      className={`px-4 py-2 rounded-full text-xs font-semibold border transition-all cursor-pointer ${
                        active 
                          ? 'bg-black text-white border-black' 
                          : 'bg-white text-gray-500 border-gray-200 hover:bg-gray-50'
                      }`}
                    >
                      {spot}
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="w-full h-36 rounded-xl overflow-hidden bg-gray-100 border border-gray-200/50 relative shadow-inner">
              <img
                alt="Central map preview"
                className="w-full h-full object-cover opacity-50"
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuCoR-0dEwlgYcOWWzTFHbZN_IcIgSThxMtBjTHyN9-68wZDw6SPWUyI8kHQ5onMidoP8eELUaUNNCTRy6KELzXg07rPayznx-SQYiAzUPoydgfARoxzk-2d63M-WMwZdD8MJHJdSJAOE1SlJRwqDhBiVtBzbVsv_AvnI_5F0Mec6kuU5Gf4TzkEeYKZ55mdLEnF4W_2nmeHDVJQ32ZTBRmjAzAoi5RbW2_2E2Kpj7u5q-ogZuyFHhTQd5QO-GwbBKI5pPPJCUZcuH0"
                referrerPolicy="no-referrer"
              />
              <div className="absolute inset-0 flex items-center justify-center">
                <MapPin className="w-6 h-6 text-black shrink-0" />
              </div>
            </div>
          </div>
        )}

        {/* Step 4: Portfolio & Social */}
        {step === 4 && (
          <div className="space-y-6 animate-fade-in">
            <h2 className="text-xl font-bold text-black font-sans">作品集與社交平台 (4/6)</h2>

            <div className="p-6 border-2 border-dashed border-gray-300 hover:border-black rounded-2xl flex flex-col items-center justify-center text-center hover:bg-neutral-50 cursor-pointer transition-colors duration-200">
              <UploadCloud className="w-10 h-10 text-gray-400 mb-2" />
              <p className="text-sm font-semibold text-gray-700">點擊或拖放照片到此處上傳</p>
              <p className="text-[11px] text-gray-400 mt-1 font-medium leading-none">最多上傳 10 張，支援 JPG, PNG, MP4 錄像</p>
            </div>

            <div className="space-y-4">
              <div className="flex items-center gap-3 bg-white border border-gray-200 rounded-lg p-3">
                <Link className="w-4 h-4 text-gray-400 shrink-0" />
                <input
                  type="text"
                  className="w-full bg-transparent border-none p-0 text-sm focus:outline-none focus:ring-0"
                  placeholder="Instagram 帳號連結"
                />
              </div>

              <div className="flex items-center gap-3 bg-white border border-gray-200 rounded-lg p-3">
                <Link className="w-4 h-4 text-gray-400 shrink-0" />
                <input
                  type="text"
                  className="w-full bg-transparent border-none p-0 text-sm focus:outline-none focus:ring-0"
                  placeholder="TikTok 創作者影片連結"
                />
              </div>
            </div>
          </div>
        )}

        {/* Step 5: Pricing */}
        {step === 5 && (
          <div className="space-y-6 animate-fade-in">
            <h2 className="text-xl font-bold text-black font-sans">服務定價設定 (5/6)</h2>
            <p className="text-xs text-gray-400 leading-normal font-semibold">請填寫提供項目的個人起步定價（基數：港幣 HKD）</p>

            <div className="space-y-3.5">
              {[
                { title: '洗剪吹造型', icon: <Scissors className="w-4 h-4 text-black mr-2" />, placeholder: '480' },
                { title: '全頭染髮', icon: <BadgeDollarSign className="w-4 h-4 text-black mr-2" />, placeholder: '880' },
                { title: '電髮造型', icon: <PlusCircle className="w-4 h-4 text-black mr-2" />, placeholder: '1280' },
                { title: '頭皮/極緻護理', icon: <ShieldCheck className="w-4 h-4 text-black mr-2" />, placeholder: '680' }
              ].map((item, idx) => (
                <div key={idx} className="flex items-center justify-between p-4 bg-white rounded-xl border border-gray-200">
                  <div className="flex items-center font-semibold text-sm">
                    {item.icon}
                    <span>{item.title}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-gray-400 font-bold uppercase">HKD</span>
                    <input
                      type="number"
                      className="w-24 text-right border-0 border-b border-gray-300 focus:border-black focus:ring-0 p-1 font-bold"
                      placeholder={item.placeholder}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Step 6: Availability list */}
        {step === 6 && (
          <div className="space-y-6 animate-fade-in">
            <h2 className="text-xl font-bold text-black font-sans">排班與营业時間 (6/6)</h2>

            <div className="space-y-3">
              <label className="text-xs font-semibold text-gray-400 uppercase tracking-widest">每週營業時段</label>
              <div className="space-y-3">
                {['週一', '週二', '週五'].map((day) => (
                  <div key={day} className="flex items-center justify-between py-2 border-b border-gray-150">
                    <span className="font-bold text-sm">{day}</span>
                    <div className="flex items-center gap-3">
                      <input type="time" className="bg-transparent border-none p-0 text-xs focus:ring-0" defaultValue="10:00" />
                      <span className="text-xs text-gray-400 font-semibold uppercase">至</span>
                      <input type="time" className="bg-transparent border-none p-0 text-xs focus:ring-0" defaultValue="20:00" />
                    </div>
                  </div>
                ))}
                <div className="flex items-center justify-between py-2 border-b border-gray-150 opacity-40">
                  <span className="font-bold text-sm">週日</span>
                  <p className="text-xs text-black font-bold flex items-center gap-1">
                    <CalendarOff className="w-3.5 h-3.5" />
                    <span>休息日</span>
                  </p>
                </div>
              </div>
            </div>

            <div className="space-y-3">
              <label className="text-xs font-semibold text-gray-400 uppercase tracking-widest">排期及假勤設定</label>
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => alert('公眾假期自動匯入與排休已同步！')}
                  className="flex-1 p-4 rounded-xl border border-gray-200 bg-white text-left hover:bg-neutral-50 transition-colors cursor-pointer"
                >
                  <Clock className="w-5 h-5 text-black mb-1.5" />
                  <p className="font-bold text-xs text-gray-800">設定法休/國定假</p>
                </button>
                <button
                  type="button"
                  onClick={() => alert('已為您跳轉週日臨時特別休假申請！')}
                  className="flex-1 p-4 rounded-xl border border-gray-200 bg-white text-left hover:bg-neutral-50 transition-colors cursor-pointer"
                >
                  <CalendarOff className="w-5 h-5 text-black mb-1.5" />
                  <p className="font-bold text-xs text-gray-800">請特休/短期公休</p>
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Global Progress Indicators / Button Group */}
        <div className="fixed bottom-0 left-0 w-full bg-white px-5 py-4 flex gap-4 border-t border-gray-100 z-50 md:relative md:bg-transparent md:border-none md:px-0 md:mt-12">
          {step > 1 && (
            <button
              type="button"
              onClick={handlePrev}
              className="flex-1 h-12 rounded-xl border border-black hover:bg-gray-50 text-black font-bold text-sm active:scale-95 transition-all cursor-pointer"
            >
              上一步
            </button>
          )}
          <button
            type="button"
            onClick={handleNext}
            className={`flex-1 h-12 rounded-xl font-bold text-sm active:scale-95 transition-all cursor-pointer ${
              step === totalSteps
                ? 'bg-amber-400 hover:bg-amber-300 text-black shadow-md'
                : 'bg-black text-white hover:bg-neutral-800 shadow-xs'
            }`}
          >
            {step === totalSteps ? '提交申請' : '下一步'}
          </button>
        </div>
      </main>
    </div>
  );
}
