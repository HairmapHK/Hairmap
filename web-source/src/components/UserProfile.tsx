import React, { useState } from 'react';
import { Booking, Service } from '../types';
import { Mail, Phone, Award, ShieldCheck, Scissors, Bookmark, ChevronRight, Calendar, Bell, SlidersHorizontal, Search } from 'lucide-react';

interface UserProfileProps {
  bookings: Booking[];
  onCancelBooking: (id: string) => void;
  onApplyStylist: () => void;
  onSelectStylist: (id: string) => void;
  currentUser?: { nickname: string; email: string };
  onLogout?: () => void;
}

export default function UserProfile({ 
  bookings, 
  onCancelBooking, 
  onApplyStylist, 
  onSelectStylist,
  currentUser = { nickname: 'Alex Chen', email: 'alex.chen@gmail.com' },
  onLogout
}: UserProfileProps) {
  const [activeTab, setActiveTab] = useState<'upcoming' | 'history'>('upcoming');

  const upcomingBookings = bookings.filter((b) => b.status === 'upcoming');
  const historyBookings = bookings.filter((b) => b.status === 'history')
    .concat([
      {
        id: 'hist1',
        salonName: '旺角旗艦店 - The Hair Lab',
        stylistName: 'Jessica Ho',
        date: '2026-05-18',
        timeSlot: '11:00 - 12:30',
        serviceName: '縮毛矯正',
        price: 980,
        status: 'history'
      }
    ]);

  const displayedBookings = activeTab === 'upcoming' ? upcomingBookings : historyBookings;

  const stylePreferences = ['韓系紋理燙', '簡約油頭', '歐美漸層 Fade'];

  const favorites = [
    {
      id: 'fav1',
      title: 'Noir Studio',
      subtitle: '尖沙咀 · 髮廊',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDjxPbEIx45OCMBgJZtxL55Y95TPAK7olPj67xmiv8Phfba4imdTcf8Gbqzcf1XPizbcFKmyN7i1jBVkWRib7fSijLwTUc3qCAld5n3GIKBBEA2J83hrNhC5wUesiOP_Au3KwIJWrhoZMHqoPaxxlHgelv1Bdr-G4OAzTs0lFGdnw6hzBNqa9bHP2kvqo6y8CRdBmUk_BWs0Z5gHLjJbTbLpxXS9WywwJyoGQAaJmupok2zAezEwWk5P1fiVRmbRBpCQUcARfx2Z6Q'
    },
    {
      id: 'fav2',
      title: 'Isabella H.',
      subtitle: '資深設計師',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCdt34UIOKOkwc2bGPh9vy_aUdrx563x-z-eHohATICpH5SM-uWqkJfZ2MU-En1j_9ZQfH-LLAgw9hrJ0TJFBFvBOcLAWGYOca8gck4pCSlpM9h4gTN5WmgwFiRtQWKpn6x4qOAfXu0hK_phT2nfrVZqLpA4GuDypNHCoxsqeDGgBkeBddn7M-x0pD2aFQ8p-jbYAR4IJKFfRiGmJKF1AuFJZNSK3hMn_raprAZ35gA8bvxflugrR-OpmbxsYrcykibTGtD0vB3uRA'
    },
    {
      id: 'fav3',
      title: '法式捲髮範本',
      subtitle: '造型靈感',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBkyZaysngVMvyG7EnQpNaovAavmXHPQNVcnmyWq9ygKgyUwo47rTX7eoNsfyDYj8IdTIlzuE1qpEaLOc31uQqOkAXieqMNsF1XsywJiadSITNK88PcsQ-1ZhuOlH0qNXjV-g-p3crlW4KMCIFbFwXZZ6ZUhmQCsgIGxQlphA78OOxMnWKJkNNrCwqwN8Dzx2yTT4uDMq9sH-k3hkKJFxBvaqEzcuVdDDri_SnhbRWaacIjH47XNSpD-ycDsoGYTFZgySbzRd1W3IY'
    }
  ];

  return (
    <div className="w-full h-full bg-[#fcfcfc] text-gray-900 overflow-y-auto no-scrollbar pb-24 animate-fade-in">
      {/* Top App Bar template profile */}
      <header className="w-full top-0 sticky z-40 bg-white flex justify-between items-center px-5 py-4 border-b border-gray-100 shadow-3xs shrink-0">
        <h1 className="font-serif text-3xl font-bold tracking-tighter text-black">Hairmap</h1>
        <div className="flex items-center gap-4">
          <button className="text-black hover:opacity-75 transition-opacity active:scale-95 cursor-pointer">
            <Search className="w-5 h-5 animate-pulse" />
          </button>
          <button className="text-black hover:opacity-75 transition-opacity active:scale-95 cursor-pointer">
            <SlidersHorizontal className="w-5 h-5" />
          </button>
          {onLogout && (
            <button 
              onClick={onLogout}
              className="text-xs bg-rose-50 text-rose-600 hover:bg-rose-100 border border-rose-200/50 px-2.5 py-1.5 rounded-xl font-bold transition-all active:scale-95 cursor-pointer"
            >
              登出
            </button>
          )}
        </div>
      </header>

      <main className="max-w-md mx-auto px-5 space-y-6 pt-4">
        {/* User Card info Header */}
        <section className="flex flex-col items-center text-center space-y-3 py-4">
          <div className="relative">
            <img
              alt="Alex Chen user avatar"
              className="w-28 h-28 rounded-full object-cover border-4 border-white shadow-md"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuAkKxvDZ5XVAx1_q2y2-QElvuoCJeFGH-SszYmQyjmXyxJWmUpJ3UuLefbZ1QDKC0VU8Uew4mUwhHurD6pypaaEWaRZeyJcWuxvA3yaDZ2NvX4aMkK6Nbm5a6Nqw3XJNGHqAI8KwDLsB8TXF9R9DucquP4e_p6U4mBTKjAOCcZlbqHd4nWn3AuK8aDr0PYu_5LOoVTTW_E6X_xq_s9n8u_8AjsEFJqA-vzd8owln7XKzKgYoqasw_1Gp7v6qFr0iCalAFdL5VkyXZo"
              referrerPolicy="no-referrer"
            />
            <div className="absolute bottom-0 right-1 bg-amber-400 text-black p-1.5 rounded-full border-2 border-white shadow-md">
              <ShieldCheck className="w-4 h-4" />
            </div>
          </div>
          <div>
            <h2 className="font-bold text-xl text-gray-900 leading-tight">{currentUser.nickname}</h2>
            <div className="inline-flex items-center gap-1 bg-amber-100 text-amber-900 px-3.5 py-1 rounded-full mt-2 border border-amber-200/50">
              <Award className="w-4 h-4 fill-amber-300 text-amber-800" />
              <span className="text-[11px] font-bold uppercase tracking-wider">黃金會員 Gold Member</span>
            </div>
          </div>
        </section>

        {/* Professional recruitment entrance CTA */}
        <section className="relative overflow-hidden bg-neutral-950 p-5 rounded-2xl flex items-center justify-between text-white shadow-md">
          <div className="z-10 max-w-[70%] space-y-1">
            <h3 className="font-bold text-base text-white">加入專業團隊</h3>
            <p className="text-xs text-gray-400 leading-normal">申請成為 Hairmap 合作髮型師</p>
            <button
              onClick={onApplyStylist}
              className="mt-3.5 bg-amber-400 text-black hover:bg-amber-300 hover:scale-[1.02] font-bold text-xs px-5 py-2.5 rounded-full transition-all active:scale-[0.98] cursor-pointer"
            >
              立即申請 Apply Now
            </button>
          </div>
          <Scissors className="absolute right-[-15px] bottom-[-15px] w-28 h-28 text-white/5 rotate-12 shrink-0 pointer-events-none" />
        </section>

        {/* Email, Phone, preferences */}
        <section className="space-y-4">
          <h3 className="font-bold text-base text-gray-900 border-b border-gray-100 pb-2">個人資訊與偏好</h3>
          <div className="space-y-3">
            <div className="flex items-center p-4 bg-gray-50 rounded-2xl border border-gray-100">
              <Mail className="w-5 h-5 text-gray-500 mr-4 shrink-0" />
              <div>
                <p className="text-[10px] text-gray-400 font-semibold uppercase leading-none">電子郵件</p>
                <p className="font-medium text-sm text-gray-800 mt-1">{currentUser.email}</p>
              </div>
            </div>

            <div className="flex items-center p-4 bg-gray-50 rounded-2xl border border-gray-100">
              <Phone className="w-5 h-5 text-gray-500 mr-4 shrink-0" />
              <div>
                <p className="text-[10px] text-gray-400 font-semibold uppercase leading-none">聯絡電話</p>
                <p className="font-medium text-sm text-gray-800 mt-1">+852 9123 4567</p>
              </div>
            </div>

            <div className="p-4 bg-gray-50 rounded-2xl border border-gray-100 space-y-3">
              <div className="flex items-center">
                <SlidersHorizontal className="w-5 h-5 text-gray-500 mr-4 shrink-0" />
                <p className="text-[10px] text-gray-400 font-semibold uppercase leading-none">髮型偏好 Styles</p>
              </div>
              <div className="flex flex-wrap gap-1.5">
                {stylePreferences.map((style) => (
                  <span
                    key={style}
                    className="bg-white px-3 py-1 rounded-full text-xs font-semibold text-gray-700 border border-gray-200/60 shadow-2xs"
                  >
                    {style}
                  </span>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* My Bookings switcher tabs */}
        <section className="space-y-4">
          <div className="flex justify-between items-end border-b border-gray-100 pb-2">
            <h3 className="font-bold text-base text-gray-900">我的預約</h3>
            <div className="flex gap-4">
              <button
                onClick={() => setActiveTab('upcoming')}
                className={`font-semibold text-xs pb-1 transition-all cursor-pointer ${
                  activeTab === 'upcoming' 
                    ? 'text-black border-b-2 border-black scale-102' 
                    : 'text-gray-400 hover:text-black'
                }`}
              >
                進行中
              </button>
              <button
                onClick={() => setActiveTab('history')}
                className={`font-semibold text-xs pb-1 transition-all cursor-pointer ${
                  activeTab === 'history' 
                    ? 'text-black border-b-2 border-black scale-102' 
                    : 'text-gray-400 hover:text-black'
                }`}
              >
                歷史紀錄
              </button>
            </div>
          </div>

          {/* Booking lists rendering */}
          {displayedBookings.length > 0 ? (
            <div className="space-y-4">
              {displayedBookings.map((b) => {
                const isUpcoming = b.status === 'upcoming';
                const bookingMonth = new Date(b.date).toLocaleDateString('en-US', { month: 'short' });
                const bookingDay = new Date(b.date).getDate();
                const [timeStart] = b.timeSlot.split(' - ');

                return (
                  <div
                    key={b.id}
                    className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden"
                  >
                    <div className="p-4 border-b border-gray-50 flex justify-between items-start">
                      <div>
                        <h4 className="font-bold text-sm text-gray-900">{b.salonName}</h4>
                        <p className="text-xs text-gray-500 mt-1 flex items-center gap-1">
                          <Scissors className="w-3 h-3 shrink-0" />
                          <span>髮型師: {b.stylistName}</span>
                        </p>
                      </div>
                      <span
                        className={`text-[9px] font-bold px-2 py-1 rounded tracking-wider uppercase ${
                          isUpcoming 
                            ? 'bg-amber-100 text-amber-800' 
                            : 'bg-gray-100 text-gray-400'
                        }`}
                      >
                        {isUpcoming ? '即將到來' : '已完成'}
                      </span>
                    </div>

                    <div className="p-4 bg-gray-50/55 flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="text-center bg-white px-3 py-1.5 rounded-xl border border-gray-100 min-w-[56px] shadow-2xs">
                          <p className="text-[10px] text-gray-400 font-bold uppercase leading-none">{bookingMonth}</p>
                          <p className="font-bold text-lg text-gray-900 mt-1 leading-none">{bookingDay}</p>
                        </div>
                        <div>
                          <p className="font-bold text-xs text-gray-800">{b.timeSlot}</p>
                          <p className="text-xs text-gray-500 mt-0.5">{b.serviceName}</p>
                        </div>
                      </div>
                      {isUpcoming && (
                        <button className="p-2 hover:bg-gray-100 rounded-full cursor-pointer transition-colors text-black">
                          <Bell className="w-4.5 h-4.5" />
                        </button>
                      )}
                    </div>

                    {isUpcoming && (
                      <div className="p-3 grid grid-cols-2 gap-3 border-t border-gray-50">
                        <button
                          onClick={() => alert('已為您向設計師發出變更時段諮詢中！')}
                          className="font-semibold text-xs border border-gray-200 hover:bg-gray-50 py-2.5 rounded-lg active:scale-98 transition-all cursor-pointer text-gray-700"
                        >
                          變更預約
                        </button>
                        <button
                          onClick={() => onCancelBooking(b.id)}
                          className="font-semibold text-xs bg-black text-white hover:bg-neutral-800 py-2.5 rounded-lg active:scale-98 transition-all cursor-pointer"
                        >
                          取消預約
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          ) : (
            <p className="text-center py-6 text-xs text-gray-400">尚無相關預約紀錄</p>
          )}
        </section>

        {/* Saved styles & Recently Viewed */}
        <section className="space-y-4">
          <h3 className="font-bold text-base text-gray-900 border-b border-gray-100 pb-2">我的收藏</h3>
          <div className="flex gap-4 overflow-x-auto no-scrollbar pb-2">
            {favorites.map((fav) => (
              <div
                key={fav.id}
                onClick={() => onSelectStylist('master-leo')}
                className="min-w-[130px] max-w-[130px] flex-shrink-0 group cursor-pointer"
              >
                <div className="relative aspect-[4/5] rounded-xl overflow-hidden mb-1.5 border border-gray-100 shadow-2xs">
                  <img
                    className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                    src={fav.imageUrl}
                    referrerPolicy="no-referrer"
                  />
                  <div className="absolute top-2 right-2">
                    <Bookmark className="w-4 h-4 fill-amber-400 text-amber-400 shrink-0" />
                  </div>
                </div>
                <p className="font-bold text-xs text-gray-900 truncate leading-tight">{fav.title}</p>
                <p className="text-[10px] text-gray-400 truncate mt-0.5">{fav.subtitle}</p>
              </div>
            ))}
          </div>

          {/* Recently viewed component */}
          <div className="mt-4 pt-2">
            <h4 className="text-[9px] text-gray-400 font-bold uppercase tracking-wider mb-2">最近瀏覽 Recently Viewed</h4>
            <div className="flex items-center justify-between p-3 bg-gray-50 hover:bg-gray-100/50 rounded-xl border border-gray-100 transition-colors cursor-pointer">
              <div className="flex items-center gap-3">
                <img
                  alt="The Hair Lab thumbnail"
                  className="w-12 h-12 rounded-lg object-cover border border-gray-200/50"
                  src="https://lh3.googleusercontent.com/aida-public/AB6AXuCvg2DcjfEpDFSiiWfPTiwAhAi0jU3FNp2mGKPjY3AQMPH1wEybaXa_VDFH5NNgAM9XioLKnrwzM_coLeosKlftE-G6rpiu_JLftfkrgVx-bYNiVr8J-1_P_VwJtwFfXVEML2EnK11nAnWk8P55ZWy77pZXQgcfiG3j0GSiHyQbLRyaPCBwF5ULOtfvCfRl6KyLBQHpua7lKrNbXa6UZXeS6nRS-mTEOBlanapojK0hL0EEBLcBPIs-tBED0RayjTJtNJswQyeHFJg"
                  referrerPolicy="no-referrer"
                />
                <div>
                  <p className="font-bold text-xs text-gray-800">The Hair Lab</p>
                  <p className="text-[10px] text-gray-400 leading-none mt-1">旺角 · 2天前瀏覽</p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-gray-400 shrink-0" />
            </div>
          </div>
        </section>
      </main>
    </div>
  );
}
