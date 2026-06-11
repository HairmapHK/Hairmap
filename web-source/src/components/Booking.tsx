import React, { useState, useEffect } from 'react';
import { stylistsData, salonsData } from '../data';
import { Service, Booking as BookingType, Stylist } from '../types';
import { 
  ArrowLeft, Info, Sun, CloudSun, Calendar as CalendarIcon, 
  Clock, Star, Sparkles, Check, ChevronRight, CheckCircle2,
  User, Phone, CalendarRange, Heart, MapPin, ChevronDown, ChevronUp, Lock, Award, Search
} from 'lucide-react';

interface BookingProps {
  selectedService: Service | null;
  initialStylistId?: string;
  bookingSource?: 'tab' | 'stylist';
  onBack: () => void;
  onConfirmBooking: (newBooking: BookingType) => void;
}

export default function Booking({ 
  selectedService: passedService, 
  initialStylistId = 'master-leo', 
  bookingSource = 'stylist',
  onBack, 
  onConfirmBooking 
}: BookingProps) {
  
  // 1. 動態判斷當前步驟 (若是由下方分頁 tab 進入，預設為 'stylist-list'；若是由檔案點 '預約' 進入，直接為 'booking-details')
  const [innerStep, setInnerStep] = useState<'stylist-list' | 'booking-details'>(
    bookingSource === 'tab' ? 'stylist-list' : 'booking-details'
  );

  // 2. 選擇之髮型師
  const [selectedStylistId, setSelectedStylistId] = useState<string>(initialStylistId);
  const stylist = stylistsData.find(s => s.id === selectedStylistId) || stylistsData[0];

  // 3. 搜尋與選擇髮型師列表 (用於底部 Tab 進入時的篩選)
  const [stylistSearchQuery, setStylistSearchQuery] = useState('');
  const [selectedSpecialty, setSelectedSpecialty] = useState<string>('all');

  // 4. 服務選擇
  const [selectedService, setSelectedService] = useState<Service | null>(passedService);

  // 自動在切換髮型師時同步該師專屬之首個服務，或者在有 passedService 且符合時保留
  useEffect(() => {
    if (passedService && stylist.services.some(s => s.id === passedService.id)) {
      setSelectedService(passedService);
    } else {
      setSelectedService(stylist.services[0] || null);
    }
  }, [selectedStylistId, passedService]);

  // 5. 聯絡姓名及電話 (自動記低用戶上次數據：Autosave & Persistence via localStorage)
  const [clientName, setClientName] = useState(() => {
    return localStorage.getItem('last_booking_name') || '';
  });
  const [clientPhone, setClientPhone] = useState(() => {
    return localStorage.getItem('last_booking_phone') || '';
  });

  // 6. 日曆功能：產生 14 天橫向 Scroll 按鈕
  const getNext14Days = () => {
    const list = [];
    const daysArr = ['週日', '週一', '週二', '週三', '週四', '週五', '週六'];
    const d = new Date();
    
    for (let i = 0; i < 14; i++) {
      const tempDate = new Date();
      tempDate.setDate(d.getDate() + i);
      
      const dayName = daysArr[tempDate.getDay()];
      const dayNum = tempDate.getDate();
      const monthNum = tempDate.getMonth() + 1;
      const fullLabel = `${monthNum}/${dayNum} (${dayName})`;
      
      list.push({
        day: dayName,
        num: String(dayNum),
        month: monthNum,
        year: tempDate.getFullYear(),
        dayIdx: tempDate.getDay(),
        full: fullLabel,
        rawDate: tempDate
      });
    }
    return list;
  };

  const datesList = getNext14Days();
  const [selectedDateIdx, setSelectedDateIdx] = useState(0);

  // 📅 展開日曆揀選狀態 (Togglable Detailed Calendar View)
  const [isCalendarExpanded, setIsCalendarExpanded] = useState(false);

  // 生成當月日曆網格 (2026年6月份示意，包含30天，並且能點擊跟橫向滾動直接同步)
  const generateJuneCalendar = () => {
    const totalDays = 30; // 6月份有30天
    const startOffset = 1; // 2026年6月1日是星期一，所以前面的格子偏移為1 (週日開始算的話是1)
    
    const daysGrid = [];
    // 補齊前置空格
    for (let i = 0; i < startOffset; i++) {
      daysGrid.push({ dayNum: 0, isCurrentMonth: false });
    }
    for (let d = 1; d <= totalDays; d++) {
      daysGrid.push({ dayNum: d, isCurrentMonth: true });
    }
    return daysGrid;
  };

  const j_calendar = generateJuneCalendar();

  // 點選日曆中的某一天
  const handleSelectCalendarDay = (dayNum: number) => {
    if (dayNum === 0) return;
    // 試圖在 datesList (14天) 中尋找是否有匹配的日期號，若有則同步 selectedDateIdx，若無則生成對應的日期
    const matchIdx = datesList.findIndex(d => d.num === String(dayNum) && d.month === 6);
    if (matchIdx !== -1) {
      setSelectedDateIdx(matchIdx);
    } else {
      // 超出 14 天的模擬，直接將第 0 個日期的天數修改為該號碼進行模擬
      setSelectedDateIdx(0);
      datesList[0].num = String(dayNum);
      datesList[0].full = `6/${dayNum} (模擬選定)`;
    }
    setIsCalendarExpanded(false);
  };

  // 7. 時間選擇網格按鈕與「已滿」狀態預約 (時間用「網格按鈕」，已滿時段 disable 並變灰色)
  // 將不同時段根據 selectedDateIdx 隨機模擬某些時段已滿，增加生動感
  const getSimulatedSlots = (dateIndex: number) => {
    // 建立 12-16 個固定時段
    const rawMorning = ['09:00', '09:30', '10:00', '10:30', '11:00', '11:30'];
    const rawAfternoon = ['13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30'];
    const rawEvening = ['17:00', '17:30', '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00'];

    // 使用日期索引模數進行僞隨機判定，使得已滿時段在切換日期時不同，切實模擬真實佔用
    const morning = rawMorning.map((t, idx) => ({
      time: t,
      available: !((idx + dateIndex) % 3 === 0 || t === '11:00') // 11:00 始終固定已滿
    }));

    const afternoon = rawAfternoon.map((t, idx) => ({
      time: t,
      available: !((idx * 2 + dateIndex) % 4 === 0 || t === '14:00' || t === '16:30') // 這些時間點已被佔用
    }));

    const evening = rawEvening.map((t, idx) => ({
      time: t,
      available: !((idx + dateIndex * 3) % 4 === 0 || t === '18:00' || t === '21:00')
    }));

    return { morning, afternoon, evening };
  };

  const currentSlots = getSimulatedSlots(selectedDateIdx);
  const [selectedTime, setSelectedTime] = useState('10:00');

  // 確認時間點是否是禁用的 (如果已滿，在切換日期後，如果上次選的時間恰好在新日期變為已滿，則重置為該天首個可用時間)
  useEffect(() => {
    const allAvailable = [
      ...currentSlots.morning,
      ...currentSlots.afternoon,
      ...currentSlots.evening
    ].filter(s => s.available);
    
    const isCurrentTimeStillAvailable = allAvailable.some(s => s.time === selectedTime);
    if (!isCurrentTimeStillAvailable && allAvailable.length > 0) {
      setSelectedTime(allAvailable[0].time);
    }
  }, [selectedDateIdx, selectedStylistId]);

  // 8. 預約確認成功彈窗 overlay 顯示狀態
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [savedBookingRecord, setSavedBookingRecord] = useState<BookingType | null>(null);

  // 價格與服務名稱計算
  const price = selectedService ? selectedService.price : 80;
  const serviceName = selectedService ? selectedService.name : '招牌剪髮';

  // 小幫手：估算結束時間
  const addMinutesToTimeString = (timeStr: string, mins: number): string => {
    try {
      const [h, m] = timeStr.split(':').map(Number);
      if (isNaN(h) || isNaN(m)) return timeStr;
      let totalMins = h * 60 + m + mins;
      let newH = Math.floor(totalMins / 60) % 24;
      let newM = totalMins % 60;
      return `${String(newH).padStart(2, '0')}:${String(newM).padStart(2, '0')}`;
    } catch (e) {
      return timeStr;
    }
  };

  // 髮廊門市地標名稱
  const getSalonForStylist = (styId: string) => {
    if (styId === 'master-leo') return 'Maison de Beauté (尖沙咀海港城)';
    if (styId === 'alex-chen') return 'Noir Studio (中環置地店)';
    if (styId === 'sarah-lin') return 'Zenith Premium (銅鑼灣時代店)';
    return 'Elysian Hair Art (旺角朗豪坊)';
  };

  // 提交預約單處理 (確認後顯示「預約成功！髮型師會收到通知」並自動記憶姓名電話)
  const handleBookingConfirmSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!clientName.trim()) {
      alert('請填寫預約人姓名，以便髮型師核對身分。');
      return;
    }
    if (!clientPhone.trim()) {
      alert('請填寫聯絡電話，以便系統推送預約提醒。');
      return;
    }

    // 🎯 自動記憶姓名跟電話 (Auto record user data)
    localStorage.setItem('last_booking_name', clientName.trim());
    localStorage.setItem('last_booking_phone', clientPhone.trim());

    const chosenDate = datesList[selectedDateIdx];
    const newBooking: BookingType = {
      id: 'b_new_' + Date.now(),
      salonName: getSalonForStylist(selectedStylistId),
      stylistName: stylist.name,
      date: `2026-${String(chosenDate.month).padStart(2, '0')}-${String(chosenDate.num).padStart(2, '0')}`,
      timeSlot: `${selectedTime} - ${addMinutesToTimeString(selectedTime, selectedService?.duration || 60)}`,
      serviceName: serviceName,
      price: price,
      status: 'upcoming'
    };

    setSavedBookingRecord(newBooking);
    setShowSuccessModal(true); // 顯示精美「預約成功」彈窗！
  };

  // 點擊彈窗確定後，真正寫入總預約紀錄並切換視窗
  const handleFinalSuccessAcknowledge = () => {
    if (savedBookingRecord) {
      onConfirmBooking(savedBookingRecord);
    }
  };

  // 篩選髮型師 (搜尋欄過濾 + 專長篩選)
  const filteredStylists = stylistsData.filter(s => {
    const matchesSearch = s.name.toLowerCase().includes(stylistSearchQuery.toLowerCase()) || 
                          s.title.includes(stylistSearchQuery);
    const matchesSpecialty = selectedSpecialty === 'all' || 
                             s.specialties.includes(selectedSpecialty);
    return matchesSearch && matchesSpecialty;
  });

  // 取得不重複的專長列表
  const allSpecialties = ['all', ...Array.from(new Set(stylistsData.flatMap(s => s.specialties)))];

  return (
    <div className="w-full h-full bg-slate-50 text-gray-950 flex flex-col relative overflow-hidden select-none">
      
      {/* 1. APP BAR REGULAR HEADER */}
      <header className="bg-white border-b border-gray-100 px-5 py-4 flex justify-between items-center shrink-0 z-30">
        <button
          onClick={() => {
            if (innerStep === 'booking-details' && bookingSource === 'tab') {
              // 底部 Tab 進來且處在詳情頁，按返回先退回到「選擇設計師列表」
              setInnerStep('stylist-list');
            } else {
              onBack();
            }
          }}
          className="active:scale-95 duration-150 transition-all cursor-pointer hover:bg-gray-100 p-2.5 rounded-full shrink-0 border border-gray-100/80"
          title="返回"
        >
          <ArrowLeft className="w-4 h-4 text-black" />
        </button>

        <span className="font-sans font-extrabold text-sm tracking-tight text-gray-900">
          {innerStep === 'stylist-list' ? '挑選髮型設計師' : '選擇日期與完成預約'}
        </span>

        <button 
          onClick={() => alert('💬 預約守則：成功提交預約後，系統將自動推播通知您與髮型師。本平台支持前日 24 小時無痛靈活異動行程。')}
          className="active:scale-95 duration-150 transition-all cursor-pointer hover:bg-gray-100 p-2 rounded-full shrink-0"
        >
          <Info className="w-4 h-4 text-amber-500" />
        </button>
      </header>

      {/* 🌟 2-A. STEP 1: SELECT STYLIST VIEW (Requirement: 如果使用者係經過底部分頁進入先顯示髮型師列表) */}
      {innerStep === 'stylist-list' && (
        <div className="flex-1 overflow-y-auto no-scrollbar pb-32 px-5 py-4 space-y-4">
          
          <div className="space-y-1.5">
            <h2 className="text-xl font-black text-gray-950 tracking-tight font-sans">
              尋找您今天的命定髮型師 ✨
            </h2>
            <p className="text-[11px] text-gray-400 font-semibold leading-normal">
              為您篩選香港、九龍區最具人氣的高明度挑染、韓式燙剪名師，可直接一鍵預訂。
            </p>
          </div>

          {/* 🔍 SEARCH AND SPECIALTIES FILTER (Requirement) */}
          <div className="space-y-2.5">
            <div className="relative">
              <input
                type="text"
                placeholder="輸入大師名字 / 標題查找..."
                value={stylistSearchQuery}
                onChange={(e) => setStylistSearchQuery(e.target.value)}
                className="w-full bg-white border border-gray-150 focus:border-black focus:ring-0 rounded-xl px-9 py-3 text-xs placeholder-gray-400"
              />
              <Search className="absolute left-3 top-3.5 w-3.5 h-3.5 text-gray-400" />
            </div>

            {/* Specialties tag grid list */}
            <div className="flex gap-1.5 overflow-x-auto no-scrollbar py-0.5">
              {allSpecialties.map(spec => (
                <button
                  key={spec}
                  onClick={() => setSelectedSpecialty(spec)}
                  className={`text-[10px] font-black px-3 py-1.5 rounded-full border transition-all cursor-pointer ${
                    selectedSpecialty === spec
                      ? 'bg-neutral-900 border-neutral-900 text-amber-300'
                      : 'bg-white border-gray-150 text-gray-500 hover:border-gray-300'
                  }`}
                >
                  {spec === 'all' ? '全部專長' : spec}
                </button>
              ))}
            </div>
          </div>

          {/* STYLISTS LIST STACK */}
          <div className="space-y-3.5 pt-1">
            {filteredStylists.length > 0 ? (
              filteredStylists.map((sty) => (
                <div
                  key={sty.id}
                  onClick={() => {
                    setSelectedStylistId(sty.id);
                    setInnerStep('booking-details'); // 點擊點選後，無縫切換進入預約日曆詳細畫面
                  }}
                  className="bg-white rounded-2xl border border-gray-150/60 p-4.5 shadow-5xs hover:border-black/60 transition-all cursor-pointer flex gap-4 pr-3.5 group relative"
                >
                  {/* Badge */}
                  <span className="absolute top-3.5 right-3.5 bg-amber-400 text-black text-[8px] font-black px-1.5 py-0.5 rounded uppercase">
                    PRO
                  </span>

                  {/* Avatar section */}
                  <div className="w-16 h-16 rounded-full overflow-hidden shrink-0 border border-gray-150 relative self-center group-hover:scale-102 duration-300 transition-transform">
                    <img src={sty.avatar} alt={sty.name} className="w-full h-full object-cover" />
                    <span className="absolute bottom-0.5 right-0.5 w-3 h-3 bg-emerald-500 rounded-full border border-white animate-pulse"></span>
                  </div>

                  {/* Body details */}
                  <div className="min-w-0 flex-1 space-y-1">
                    <div className="flex items-center gap-1.5">
                      <h4 className="font-extrabold text-sm text-gray-950 font-sans group-hover:text-amber-600 duration-150">
                        {sty.name}
                      </h4>
                      <p className="text-[10px] text-gray-400 font-bold">({sty.experience})</p>
                    </div>

                    <p className="text-[10px] font-bold text-gray-500 bg-slate-50 border border-gray-100 px-2 py-0.5 rounded inline-block">
                      🏷️ {sty.title}
                    </p>

                    <div className="flex items-center gap-2">
                      <div className="flex items-center text-amber-500">
                        <Star className="w-3 h-3 fill-amber-500" />
                        <span className="text-[11px] font-black text-gray-800 ml-0.5 leading-none">{sty.rating}</span>
                      </div>
                      <span className="w-1 h-1 bg-gray-300 rounded-full"></span>
                      <p className="text-[10px] text-gray-400 font-medium">语言: {sty.languages}</p>
                    </div>

                    {/* Specialties rows */}
                    <div className="flex gap-1 flex-wrap pt-0.5">
                      {sty.specialties.map(spec => (
                        <span key={spec} className="text-[8px] font-semibold bg-amber-50 text-amber-900 border border-amber-200/50 px-1.5 py-0.5 rounded">
                          {spec}
                        </span>
                      ))}
                    </div>
                  </div>

                  <div className="shrink-0 flex items-center justify-center pl-1">
                    <div className="w-8 h-8 rounded-full bg-slate-50 hover:bg-neutral-900 hover:text-white flex items-center justify-center border border-gray-150 transition-colors">
                      <ChevronRight className="w-4 h-4 text-gray-600" />
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center py-10 bg-white border border-gray-100 rounded-2xl p-5 space-y-1">
                <p className="text-sm font-bold text-gray-800">未找到相符的髮型師 🔍</p>
                <p className="text-xs text-gray-400">請嘗試更換其他搜尋字眼或專長標籤。</p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* 📅 2-B. STEP 2: BOOKING DETAILS (Requirement: 預約操作畫面) */}
      {innerStep === 'booking-details' && (
        <form onSubmit={handleBookingConfirmSubmit} className="flex-1 overflow-y-auto no-scrollbar pb-36">
          <div className="max-w-md mx-auto px-5 py-4 space-y-5.5">
            
            {/* DESIGNER MINI PROFILE PREVIEW CARD (Came directly or selected) */}
            <div className="bg-white rounded-2xl border border-gray-150/60 p-4 flex justify-between items-center shadow-5xs">
              <div className="flex items-center gap-3 min-w-0">
                <div className="w-12 h-12 rounded-full overflow-hidden shrink-0 border border-gray-100 relative">
                  <img src={stylist.avatar} alt={stylist.name} className="w-full h-full object-cover" />
                  <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 rounded-full border border-white"></span>
                </div>
                <div className="min-w-0">
                  <p className="text-[9px] text-gray-400 font-extrabold tracking-wider uppercase">當前選擇</p>
                  <p className="font-extrabold text-xs text-gray-950 truncate flex items-center gap-1">
                    <span>{stylist.name}</span>
                    <span className="bg-amber-400 text-[8px] text-black px-1.5 py-0.2 rounded font-black font-mono">
                      大師級
                    </span>
                  </p>
                  <p className="text-[10px] text-gray-400 truncate mt-0.5 leading-none font-bold">
                    📍 {getSalonForStylist(stylist.id)}
                  </p>
                </div>
              </div>

              {bookingSource === 'tab' && (
                <button
                  type="button"
                  onClick={() => setInnerStep('stylist-list')}
                  className="bg-slate-100 hover:bg-slate-200 text-gray-700 text-[10px] font-black px-3 py-1.5 rounded-lg border border-gray-200/50 cursor-pointer active:scale-95 transition-all"
                >
                  重選設計師
                </button>
              )}
            </div>

            {/* ACTION SELECT SERVICE CATALOG */}
            <div className="space-y-2.5">
              <div className="flex justify-between items-center">
                <h3 className="text-xs font-bold text-gray-900 uppercase tracking-widest flex items-center gap-1">
                  <Award className="w-3.5 h-3.5 text-amber-500" />
                  <span>第一步：選擇預訂之沙龍項目</span>
                </h3>
                <span className="text-[9px] bg-indigo-50 text-indigo-700 font-bold px-1.5 rounded">免押預付</span>
              </div>

              <div className="grid grid-cols-1 gap-2">
                {stylist.services.map((ser) => {
                  const isSec = selectedService?.id === ser.id;
                  return (
                    <button
                      key={ser.id}
                      type="button"
                      onClick={() => setSelectedService(ser)}
                      className={`p-3.5 rounded-xl text-left border cursor-pointer transition-all flex justify-between items-center ${
                        isSec 
                          ? 'bg-neutral-900 text-white border-neutral-900 shadow-sm' 
                          : 'bg-white text-gray-700 border-gray-150/60 hover:bg-slate-50'
                      }`}
                    >
                      <div className="space-y-1 pr-2 min-w-0 flex-1">
                        <div className="flex items-center gap-1.5">
                          <p className="text-xs font-black truncate">{ser.name}</p>
                          <span className={`text-[8px] px-1 font-bold rounded ${
                            isSec ? 'bg-amber-400 text-black' : 'bg-slate-100 text-gray-500'
                          }`}>
                            {ser.duration} 分鐘
                          </span>
                        </div>
                        <p className={`text-[10px] truncate ${isSec ? 'text-gray-300' : 'text-gray-400'}`}>
                          {ser.description}
                        </p>
                      </div>
                      <div className="text-right shrink-0">
                        <span className={`text-xs font-black font-mono block ${isSec ? 'text-amber-300' : 'text-amber-950'}`}>
                          HK$ {ser.price}
                        </span>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* TWO-WAY DATE PICKER DESIGN (Requirement 3: 日期用「日曆揀選」或「橫向 scroll 日期按鈕」) */}
            <div className="space-y-2.5">
              <div className="flex justify-between items-center">
                <h3 className="text-xs font-bold text-gray-900 uppercase tracking-widest flex items-center gap-1">
                  <CalendarRange className="w-3.5 h-3.5 text-black" />
                  <span>第二步：選擇服務日期</span>
                </h3>
                
                {/* Calendars toggle trigger */}
                <button
                  type="button"
                  onClick={() => setIsCalendarExpanded(!isCalendarExpanded)}
                  className="text-[10px] text-amber-700 hover:text-amber-800 font-extrabold flex items-center gap-0.5 bg-amber-50 px-2.5 py-1 rounded-lg border border-amber-205 cursor-pointer"
                >
                  <CalendarIcon className="w-3 h-3 shrink-0" />
                  <span>{isCalendarExpanded ? '收起完整日曆 🔺' : '📅 展開完整日曆'}</span>
                </button>
              </div>

              {/* A. EXPANDED CALENDAR MODAL SELECTION (日曆揀選 - 2026年6月高質感月曆) */}
              {isCalendarExpanded && (
                <div className="bg-white border border-gray-200 rounded-2xl p-4.5 space-y-3 shadow-md animate-fade-in">
                  <div className="flex justify-between items-center pb-2 border-b border-gray-100">
                    <span className="text-xs font-black text-gray-900">2026 年 6 月</span>
                    <span className="text-[9px] text-gray-400 font-semibold">（請直接點擊天數號碼）</span>
                  </div>

                  {/* Days names header */}
                  <div className="grid grid-cols-7 text-center text-[10px] font-black text-gray-400 pb-1">
                    <span>一</span><span>二</span><span>三</span><span>四</span><span>五</span><span className="text-amber-600">六</span><span className="text-amber-600">日</span>
                  </div>

                  {/* Days grid layout map */}
                  <div className="grid grid-cols-7 gap-1.5 text-center text-xs">
                    {j_calendar.map((day, idx) => {
                      const isCurrentDayMatchSelected = datesList[selectedDateIdx].num === String(day.dayNum) && datesList[selectedDateIdx].month === 6;
                      return (
                        <div key={idx}>
                          {day.dayNum > 0 ? (
                            <button
                              type="button"
                              onClick={() => handleSelectCalendarDay(day.dayNum)}
                              className={`w-8 h-8 rounded-full flex items-center justify-center font-bold font-mono transition-all duration-200 cursor-pointer ${
                                isCurrentDayMatchSelected
                                  ? 'bg-black text-amber-300 font-black scale-105 shadow-xs'
                                  : 'hover:bg-amber-100 text-gray-800'
                              }`}
                            >
                              {day.dayNum}
                            </button>
                          ) : (
                            <div className="w-8 h-8"></div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* B. HORIZONTAL SCROLL ENHANCED BUTTONS (橫向 scroll 日期按鈕 - always active) */}
              <div className="flex gap-2 overflow-x-auto no-scrollbar py-0.5">
                {datesList.map((d, idx) => {
                  const isSelected = selectedDateIdx === idx;
                  const isWeekend = d.day === '週六' || d.day === '週日';
                  
                  return (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => {
                        setSelectedDateIdx(idx);
                        setIsCalendarExpanded(false); // 收起日曆
                      }}
                      className={`flex flex-col items-center justify-center min-w-[58px] h-18 rounded-2xl transition-all duration-300 border cursor-pointer shrink-0 ${
                        isSelected 
                          ? 'bg-neutral-950 text-white border-neutral-950 shadow-md scale-102 ring-2 ring-neutral-950/10' 
                          : 'bg-white text-gray-600 border-gray-150/60 hover:border-gray-300'
                      }`}
                    >
                      <span className={`text-[8.5px] font-black uppercase ${
                        isWeekend && !isSelected ? 'text-amber-600' : ''
                      }`}>
                        {d.day}
                      </span>
                      <span className="font-extrabold text-base mt-0.5 font-mono">{d.num}</span>
                      <span className="text-[7.5px] opacity-70 mt-0.5 scale-90">{d.month}月</span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* GRID SLOTS FOR TIMEPICKING (Requirement 4: 時間用「網格按鈕」，已滿時段 disable 並變灰色) */}
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <h3 className="text-xs font-bold text-gray-900 uppercase tracking-widest flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5 text-black" />
                  <span>第三步：選擇預約時段</span>
                </h3>
                <span className="text-[10px] text-gray-400 font-bold">目前選擇：{selectedTime}</span>
              </div>

              {/* Grid content blocks mapped under headers */}
              <div className="space-y-4">
                
                {/* 1. Morning morning */}
                <div className="space-y-2">
                  <div className="flex items-center gap-1 text-[10px] font-black text-gray-400 uppercase tracking-widest">
                    <Sun className="w-3.5 h-3.5 text-amber-500 shrink-0" />
                    <span>早上時段 (09:00 - 12:00)</span>
                  </div>
                  <div className="grid grid-cols-4 gap-2">
                    {currentSlots.morning.map((slot) => {
                      const isSelected = selectedTime === slot.time;
                      return (
                        <button
                          key={slot.time}
                          type="button"
                          disabled={!slot.available}
                          onClick={() => setSelectedTime(slot.time)}
                          className={`py-2 px-1 text-xs font-bold rounded-xl text-center transition-all border shrink-0 flex items-center justify-center gap-1 ${
                            !slot.available
                              ? 'bg-slate-100 text-gray-300/80 border-gray-100 line-through cursor-not-allowed opacity-50'
                              : isSelected
                              ? 'bg-black text-amber-300 border-black shadow-xs font-black'
                              : 'bg-white text-gray-700 border-gray-150/60 hover:border-gray-300 cursor-pointer'
                          }`}
                        >
                          {!slot.available && <Lock className="w-2.5 h-2.5 text-gray-300 shrink-0" />}
                          <span>{slot.time}</span>
                          {!slot.available && <span className="text-[8px] no-underline font-semibold text-gray-300 leading-none">已滿</span>}
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* 2. Afternoon afternoon */}
                <div className="space-y-2">
                  <div className="flex items-center gap-1 text-[10px] font-black text-gray-400 uppercase tracking-widest">
                    <CloudSun className="w-3.5 h-3.5 text-orange-400 shrink-0" />
                    <span>下午時段 (12:00 - 17:00)</span>
                  </div>
                  <div className="grid grid-cols-4 gap-2">
                    {currentSlots.afternoon.map((slot) => {
                      const isSelected = selectedTime === slot.time;
                      return (
                        <button
                          key={slot.time}
                          type="button"
                          disabled={!slot.available}
                          onClick={() => setSelectedTime(slot.time)}
                          className={`py-2 px-1 text-xs font-bold rounded-xl text-center transition-all border shrink-0 flex items-center justify-center gap-1 ${
                            !slot.available
                              ? 'bg-slate-100 text-gray-300/80 border-gray-100 line-through cursor-not-allowed opacity-50'
                              : isSelected
                              ? 'bg-black text-amber-300 border-black shadow-xs font-black'
                              : 'bg-white text-gray-700 border-gray-150/60 hover:border-gray-300 cursor-pointer'
                          }`}
                        >
                          {!slot.available && <Lock className="w-2.5 h-2.5 text-gray-300 shrink-0" />}
                          <span>{slot.time}</span>
                          {!slot.available && <span className="text-[8px] no-underline font-semibold text-gray-300 leading-none">已滿</span>}
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* 3. Evening evening */}
                <div className="space-y-2">
                  <div className="flex items-center gap-1 text-[10px] font-black text-gray-400 uppercase tracking-widest">
                    <Clock className="w-3.5 h-3.5 text-purple-400 shrink-0" />
                    <span>晚間時段 (17:00 - 21:30)</span>
                  </div>
                  <div className="grid grid-cols-4 gap-2">
                    {currentSlots.evening.map((slot) => {
                      const isSelected = selectedTime === slot.time;
                      return (
                        <button
                          key={slot.time}
                          type="button"
                          disabled={!slot.available}
                          onClick={() => setSelectedTime(slot.time)}
                          className={`py-2 px-1 text-xs font-bold rounded-xl text-center transition-all border shrink-0 flex items-center justify-center gap-1 ${
                            !slot.available
                              ? 'bg-slate-100 text-gray-300/80 border-gray-100 line-through cursor-not-allowed opacity-50'
                              : isSelected
                              ? 'bg-black text-amber-300 border-black shadow-xs font-black'
                              : 'bg-white text-gray-700 border-gray-150/60 hover:border-gray-300 cursor-pointer'
                          }`}
                        >
                          {!slot.available && <Lock className="w-2.5 h-2.5 text-gray-300 shrink-0" />}
                          <span>{slot.time}</span>
                          {!slot.available && <span className="text-[8px] no-underline font-semibold text-gray-300 leading-none">已滿</span>}
                        </button>
                      );
                    })}
                  </div>
                </div>

              </div>
            </div>

            {/* INTERACTIVE FORM INPUT FIELDS (Requirement 5: 自動記低用戶上次用嘅姓名電話) */}
            <div className="space-y-3 bg-white border border-gray-150/60 p-4.5 rounded-2xl shadow-6xs">
              <h3 className="text-xs font-black text-gray-900 uppercase tracking-widest flex items-center gap-1.5 border-b border-gray-50 pb-2">
                <User className="w-3.5 h-3.5 text-amber-600" />
                <span>第四步：填寫預約客戶聯絡資料</span>
              </h3>

              <div className="space-y-2.5">
                {/* Client Name input */}
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest block header">
                    客戶姓名 (預約人全名)
                  </label>
                  <div className="relative">
                    <input
                      type="text"
                      value={clientName}
                      onChange={(e) => setClientName(e.target.value)}
                      required
                      placeholder="例如：Alex Chen"
                      className="w-full bg-slate-50 border border-gray-150 focus:border-black focus:ring-0 rounded-xl px-9.5 py-3 text-xs placeholder-gray-400 font-bold"
                    />
                    <User className="absolute left-3.5 top-3.5 w-3.5 h-3.5 text-gray-400" />
                  </div>
                  {localStorage.getItem('last_booking_name') && (
                    <p className="text-[8.5px] text-emerald-600 font-semibold leading-none pl-1">
                      ✓ 已根據您上次的預約紀錄自動帶入姓名
                    </p>
                  )}
                </div>

                {/* Contact phone number input */}
                <div className="space-y-1">
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest block header">
                    聯絡電話 (自動記低用於簡訊認證)
                  </label>
                  <div className="relative">
                    <input
                      type="tel"
                      value={clientPhone}
                      onChange={(e) => setClientPhone(e.target.value)}
                      required
                      placeholder="例如：+852 9876 5432"
                      className="w-full bg-slate-50 border border-gray-150 focus:border-black focus:ring-0 rounded-xl px-9.5 py-3 text-xs placeholder-gray-400 font-mono font-bold"
                    />
                    <Phone className="absolute left-3.5 top-3.5 w-3.5 h-3.5 text-gray-400" />
                  </div>
                  {localStorage.getItem('last_booking_phone') && (
                    <p className="text-[8.5px] text-emerald-600 font-semibold leading-none pl-1">
                      ✓ 已根據您上次的預約紀錄自動帶入電話
                    </p>
                  )}
                </div>
              </div>
            </div>

            {/* Platform security policy */}
            <div className="bg-emerald-50/50 hover:bg-emerald-50 text-emerald-800 p-3.5 rounded-xl border border-emerald-150/50 text-[10px] font-medium leading-relaxed leading-normal flex gap-2">
              <Check className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
              <div>
                <p className="font-extrabold text-neutral-900">🔒 到店付款與安全交易承諾</p>
                <p className="text-gray-500 font-normal leading-relaxed">
                  本平台不預先收取任何取消費用，費用一律於到店完成沙龍體驗後直接支付給髮型師，請您放心預定！
                </p>
              </div>
            </div>

          </div>
        </form>
      )}

      {/* 🟢 3. FIXED FLOATING BOTTOM REDESIGNED FOOTER - VISIBLE ON BOTH SUB-STEPS */}
      <footer className="absolute bottom-0 inset-x-0 w-full bg-white/95 backdrop-blur-xl p-5 pb-6 border-t border-gray-150/80 z-20 flex flex-col gap-3.5 shadow-[0_-8px_24px_rgba(0,0,0,0.04)] justify-end">
        
        {innerStep === 'stylist-list' ? (
          <div className="space-y-1 text-center">
            <p className="text-[10px] text-gray-400 font-black uppercase tracking-wider">
              請在上方挑選您心儀的髮型設計師
            </p>
            <p className="text-[11px] text-gray-500 font-medium">
              支援香港四大核心沙龍、100% 真實客戶評價。
            </p>
          </div>
        ) : (
          <>
            <div className="flex justify-between items-center">
              <div className="space-y-0.5 min-w-0 flex-1 pr-2">
                <p className="text-[9px] text-gray-400 font-black uppercase tracking-wider leading-none">
                  預約服務 / 設計師
                </p>
                <p className="font-black text-xs text-gray-900 truncate">
                  {serviceName} ({stylist.name})
                </p>
              </div>
              
              <div className="text-right shrink-0">
                <p className="text-[9px] text-gray-400 font-black uppercase tracking-wider leading-none">
                  預留時間
                </p>
                <p className="font-black text-xs text-amber-700 mt-0.5 font-mono">
                  {datesList[selectedDateIdx].full.split(' ')[0]} {selectedTime}
                </p>
              </div>
            </div>

            <div className="flex justify-between items-center bg-gray-50 px-3.5 py-2.5 rounded-xl border border-gray-100">
              <span className="text-[9.5px] text-gray-500 font-black">應付金額 (到店直接結帳)</span>
              <span className="text-sm font-black text-gray-950 font-mono">HK$ {price}</span>
            </div>

            {/* Form submit confirmation key button */}
            <button
              onClick={(e) => {
                if (innerStep === 'booking-details') {
                  // If we are at booking-details, the submit button is inside the form, let's manually trigger confirmation
                  handleBookingConfirmSubmit(e);
                }
              }}
              type="button"
              className="w-full bg-amber-400 hover:bg-amber-500 text-black font-black py-4 rounded-xl flex items-center justify-center gap-2 transform active:scale-[0.98] transition-all shadow-md cursor-pointer text-xs uppercase"
            >
              <span>立即預約確認時間</span>
              <ChevronRight className="w-4 h-4 text-black stroke-[3.5]" />
            </button>
          </>
        )}
      </footer>

      {/* 🎉 4. SIMPLIFIED NORMAL SUCCESS POPUP */}
      {showSuccessModal && savedBookingRecord && (
        <div className="absolute inset-0 bg-black/55 z-55 flex items-center justify-center p-6 animate-fade-in text-gray-900/90 [color-scheme:light]">
          <div className="bg-white rounded-2xl p-5 shadow-2xl max-w-xs w-full space-y-4 text-center border border-gray-100">
            
            {/* Standard Green Alert Tick */}
            <div className="w-12 h-12 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-6 h-6 stroke-[2.5]" />
            </div>

            {/* Title requested */}
            <div className="space-y-1">
              <h2 className="text-sm font-black text-gray-950 tracking-tight">
                預約成功！髮型師會收到通知
              </h2>
              <p className="text-[10.5px] text-gray-500 font-medium">
                已將預約資訊提交至系統並同步至髮型師管理後端。
              </p>
            </div>

            {/* Simple details */}
            <div className="bg-neutral-50 rounded-xl p-3 text-left text-[11px] space-y-1.5 text-neutral-700">
              <p>💇 髮型師：<strong>{savedBookingRecord.stylistName}</strong></p>
              <p>✂️ 服務項目：<strong>{savedBookingRecord.serviceName}</strong></p>
              <p>📅 預約日期：<strong>{savedBookingRecord.date}</strong></p>
              <p>⏱️ 預定時段：<strong>{savedBookingRecord.timeSlot}</strong></p>
              <p>💰 到店付款：<strong className="text-emerald-600 font-mono">HK$ {savedBookingRecord.price}</strong></p>
            </div>

            {/* Dismiss check */}
            <button
              onClick={handleFinalSuccessAcknowledge}
              className="w-full bg-neutral-950 text-white hover:bg-neutral-800 text-xs font-bold py-2.5 rounded-xl transition-all cursor-pointer shadow"
            >
              確定
            </button>
          </div>
        </div>
      )}

    </div>
  );
}
