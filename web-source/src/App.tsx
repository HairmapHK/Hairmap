import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ActiveView, Booking as BookingType, Service } from './types';
import { initialBookings } from './data';

// Components
import Onboarding from './components/Onboarding';
import Discovery from './components/Discovery';
import Inspiration from './components/Inspiration';
import StylistProfile from './components/StylistProfile';
import SalonProfile from './components/SalonProfile';
import Booking from './components/Booking';
import Chat from './components/Chat';
import UserProfile from './components/UserProfile';
import StylistApplication from './components/StylistApplication';
import StylistDashboard from './components/StylistDashboard';

// Navigation Icons
import { Search, Sparkles, Calendar, MessageSquare, User } from 'lucide-react';

export default function App() {
  const [activeView, setActiveView] = useState<ActiveView>('onboarding');
  const [userRole, setUserRole] = useState<'customer' | 'stylist'>('customer');
  const [bookings, setBookings] = useState<BookingType[]>(initialBookings);
  const [selectedService, setSelectedService] = useState<Service | null>(null);
  const [currentUser, setCurrentUser] = useState({
    nickname: 'Alex Chen',
    email: 'alex.chen@gmail.com',
    stylistTitle: '首席設計師'
  });
  const [selectedStylistId, setSelectedStylistId] = useState<string>('master-leo');
  const [selectedSalonId, setSelectedSalonId] = useState<string>('s1');
  const [bookingSource, setBookingSource] = useState<'tab' | 'stylist'>('stylist');

  // Handle cancel booking
  const handleCancelBooking = (id: string) => {
    if (window.confirm('確定要取消此預約時段嗎？')) {
      setBookings((prev) => prev.filter((b) => b.id !== id));
      alert('預約已取消成功！已退還您的預付款項。');
    }
  };

  // Add new booking
  const handleConfirmBooking = (newBooking: BookingType) => {
    setBookings((prev) => [newBooking, ...prev]);
    alert('🎉 預約成功！已為您通知 Master Leo，並可在「個人偏好」中查看進行中的預約項目。');
    setActiveView('profile'); // Redirect to profile
  };

  return (
    <div className="min-h-screen bg-neutral-100 flex items-center justify-center font-sans">
      {/* Mobile simulator frame Container for desktop, full screen on mobile */}
      <div className="relative w-full max-w-md h-[92vh] md:h-[860px] bg-white rounded-none md:rounded-[36px] shadow-none md:shadow-2xl overflow-hidden border-0 md:border-8 border-neutral-900 flex flex-col">
        
        {/* Mock top phone notch bar on desktop screen sizes */}
        <div className="hidden md:flex absolute top-0 inset-x-0 h-6 bg-black z-50 items-center justify-between px-6 text-white text-[10px]">
          <span>09:41</span>
          <div className="w-16 h-4 bg-black rounded-b-xl absolute left-1/2 transform -translate-x-1/2"></div>
          <div className="flex items-center gap-1">
            <span className="w-2.5 h-2.5 bg-white/20 rounded-full inline-block"></span>
            <span className="w-2.5 h-2.5 bg-white/40 rounded-full inline-block"></span>
            <span className="w-4 h-2.5 bg-white/80 rounded-sm inline-block"></span>
          </div>
        </div>

        {/* Dynamic Display Area with smooth AnimatePresence transition */}
        <div className="flex-1 w-full overflow-hidden relative select-none md:pt-6">
          <AnimatePresence mode="wait">
            <motion.div
              key={userRole === 'stylist' ? 'stylist-dashboard' : activeView}
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -15 }}
              transition={{ duration: 0.28, ease: 'easeOut' }}
              className="w-full h-full"
            >
              {userRole === 'stylist' ? (
                <StylistDashboard
                  initialStylistId="master-leo"
                  initialName={currentUser.nickname}
                  initialTitle={currentUser.stylistTitle}
                  onLogout={() => {
                    setUserRole('customer');
                    setActiveView('onboarding');
                  }}
                />
              ) : (
                <>
                  {activeView === 'onboarding' && (
                    <Onboarding onStart={(user, role) => {
                      if (user) {
                        setCurrentUser(user);
                      }
                      if (role === 'stylist') {
                        setUserRole('stylist');
                      } else {
                        setUserRole('customer');
                        setActiveView('discovery');
                      }
                    }} />
                  )}
                  {activeView === 'discovery' && (
                    <Discovery 
                      onSelectStylist={(id) => {
                        setSelectedStylistId(id);
                        setActiveView('stylist-profile');
                      }} 
                      onSelectSalon={(id) => {
                        setSelectedSalonId(id);
                        setActiveView('salon-profile');
                      }}
                    />
                  )}
                  {activeView === 'inspiration' && (
                    <Inspiration 
                      onSelectStylist={(id) => {
                        setSelectedStylistId(id);
                        setActiveView('stylist-profile');
                      }} 
                      onSelectSalon={(id) => {
                        setSelectedSalonId(id);
                        setActiveView('salon-profile');
                      }}
                    />
                  )}
                  {activeView === 'stylist-profile' && (
                    <StylistProfile
                      stylistId={selectedStylistId}
                      onBack={() => setActiveView('discovery')}
                      onBook={(service) => {
                        setSelectedService(service);
                        setBookingSource('stylist');
                        setActiveView('booking');
                      }}
                      onChat={() => setActiveView('chat')}
                    />
                  )}
                  {activeView === 'salon-profile' && (
                    <SalonProfile
                      salonId={selectedSalonId}
                      onBack={() => setActiveView('discovery')}
                      onSelectStylist={(id) => {
                        setSelectedStylistId(id);
                        setActiveView('stylist-profile');
                      }}
                    />
                  )}
                  {activeView === 'booking' && (
                    <Booking
                      selectedService={selectedService}
                      initialStylistId={selectedStylistId}
                      bookingSource={bookingSource}
                      onBack={() => {
                        if (bookingSource === 'tab') {
                          setActiveView('discovery');
                        } else {
                          setActiveView('stylist-profile');
                        }
                      }}
                      onConfirmBooking={handleConfirmBooking}
                    />
                  )}
                  {activeView === 'chat' && (
                    <Chat onBack={() => setActiveView('discovery')} />
                  )}
                  {activeView === 'profile' && (
                    <UserProfile
                      bookings={bookings}
                      onCancelBooking={handleCancelBooking}
                      onApplyStylist={() => setActiveView('become-stylist')}
                      onSelectStylist={(id) => {
                        setSelectedStylistId(id);
                        setActiveView('stylist-profile');
                      }}
                      currentUser={currentUser}
                      onLogout={() => {
                        setActiveView('onboarding');
                      }}
                    />
                  )}
                  {activeView === 'become-stylist' && (
                    <StylistApplication
                      onBack={() => setActiveView('profile')}
                      onSubmitSuccess={() => setActiveView('profile')}
                    />
                  )}
                </>
              )}
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Bottom Tab Navigation bar, hidden during walkthroughs, chats, profiles and checkout booking pages */}
        {userRole === 'customer' && ['discovery', 'inspiration', 'profile'].includes(activeView) && (
          <nav className="fixed bottom-0 inset-x-0 max-w-none md:max-w-md md:absolute md:bottom-0 bg-white/95 backdrop-blur-xl border-t border-gray-150 py-3 flex justify-around items-center z-45 shadow-[0_-8px_24px_rgba(0,0,0,0.03)] rounded-b-none md:rounded-b-[28px]">
            <button
              onClick={() => setActiveView('discovery')}
              className={`flex flex-col items-center justify-center transition-all duration-300 active:scale-95 cursor-pointer ${
                activeView === 'discovery' || activeView === 'booking' || activeView === 'stylist-profile'
                  ? 'text-black font-semibold scale-102'
                  : 'text-gray-400 hover:text-black'
              }`}
            >
              <Search className="w-5 h-5 shrink-0" />
              <span className="text-[10px] mt-1 font-sans">探索</span>
              {(activeView === 'discovery' || activeView === 'booking' || activeView === 'stylist-profile') && (
                <span className="w-1 h-1 bg-black rounded-full mt-0.5" />
              )}
            </button>

            <button
              onClick={() => setActiveView('inspiration')}
              className={`flex flex-col items-center justify-center transition-all duration-300 active:scale-95 cursor-pointer ${
                activeView === 'inspiration'
                  ? 'text-black font-semibold scale-102'
                  : 'text-gray-400 hover:text-black'
              }`}
            >
              <Sparkles className="w-5 h-5 shrink-0" />
              <span className="text-[10px] mt-1 font-sans">靈感</span>
              {activeView === 'inspiration' && (
                <span className="w-1 h-1 bg-black rounded-full mt-0.5" />
              )}
            </button>

            <button
              onClick={() => {
                setSelectedService(null);
                setBookingSource('tab');
                setActiveView('booking');
              }}
              className={`flex flex-col items-center justify-center transition-all duration-300 active:scale-95 cursor-pointer ${
                activeView === 'booking'
                  ? 'text-black font-semibold scale-102'
                  : 'text-gray-400 hover:text-black'
              }`}
            >
              <Calendar className="w-5 h-5 shrink-0" />
              <span className="text-[10px] mt-1 font-sans">預約</span>
              {activeView === 'booking' && (
                <span className="w-1 h-1 bg-black rounded-full mt-0.5" />
              )}
            </button>

            <button
              onClick={() => setActiveView('chat')}
              className={`flex flex-col items-center justify-center transition-all duration-300 active:scale-95 cursor-pointer relative ${
                activeView === 'chat'
                  ? 'text-black font-semibold scale-102'
                  : 'text-gray-400 hover:text-black'
              }`}
            >
              <MessageSquare className="w-5 h-5 shrink-0" />
              <span className="text-[10px] mt-1 font-sans">訊息</span>
              {activeView === 'chat' && (
                <span className="w-1 h-1 bg-black rounded-full mt-0.5" />
              )}
              {/* Mock active unread badge */}
              {activeView !== 'chat' && (
                <span className="absolute top-0 right-3.5 w-2 h-2 bg-rose-500 rounded-full border border-white" />
              )}
            </button>

            <button
              onClick={() => setActiveView('profile')}
              className={`flex flex-col items-center justify-center transition-all duration-300 active:scale-95 cursor-pointer ${
                activeView === 'profile'
                  ? 'text-black font-semibold scale-102'
                  : 'text-gray-400 hover:text-black'
              }`}
            >
              <User className="w-5 h-5 shrink-0" />
              <span className="text-[10px] mt-1 font-sans">個人</span>
              {activeView === 'profile' && (
                <span className="w-1 h-1 bg-black rounded-full mt-0.5" />
              )}
            </button>
          </nav>
        )}
      </div>
    </div>
  );
}
