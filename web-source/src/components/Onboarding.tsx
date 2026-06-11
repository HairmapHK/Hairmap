import React, { useState } from 'react';
import { ArrowLeft, User, Mail, Lock, Eye, EyeOff, AlertCircle } from 'lucide-react';

interface OnboardingProps {
  onStart: (user?: { nickname: string; email: string; stylistTitle?: string }, role?: 'customer' | 'stylist') => void;
}

export default function Onboarding({ onStart }: OnboardingProps) {
  const [role, setRole] = useState<'customer' | 'stylist'>('customer');
  const [mode, setMode] = useState<'welcome' | 'register' | 'login'>('welcome');
  const [nickname, setNickname] = useState('');
  const [stylistTitle, setStylistTitle] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const resetForm = () => {
    setNickname('');
    setStylistTitle('');
    setEmail('');
    setPassword('');
    setConfirmPassword('');
    setShowPassword(false);
    setError('');
  };

  const handleSwitchMode = (newMode: 'welcome' | 'register' | 'login') => {
    resetForm();
    setMode(newMode);
  };

  const validateEmail = (val: string) => {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val);
  };

  const handleRegisterSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!nickname.trim()) {
      setError('請輸入使用者暱稱');
      return;
    }
    if (!email.trim()) {
      setError('請輸入電子郵箱');
      return;
    }
    if (!validateEmail(email)) {
      setError('請輸入格式正確的電子郵箱');
      return;
    }
    if (!password) {
      setError('請輸入密碼');
      return;
    }
    if (password.length < 6) {
      setError('密碼長度必須至少為 6 位字元');
      return;
    }
    if (password !== confirmPassword) {
      setError('兩次輸入的密碼不一致');
      return;
    }

    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      onStart({ nickname, email, stylistTitle: role === 'stylist' ? (stylistTitle || '進階美髮設計師') : undefined }, role);
    }, 1200);
  };

  const handleLoginSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!email.trim()) {
      setError('請輸入電子郵箱');
      return;
    }
    if (!validateEmail(email)) {
      setError('請輸入格式正確的電子郵箱');
      return;
    }
    if (!password) {
      setError('請輸入密碼');
      return;
    }

    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      // Auto-derived nickname from email for simple mock demo
      const derivedNickname = email.split('@')[0];
      onStart({ 
        nickname: role === 'stylist' ? 'Master Leo' : derivedNickname, 
        email, 
        stylistTitle: role === 'stylist' ? '首席名店設計師 (沙龍合夥人)' : undefined 
      }, role);
    }, 1000);
  };

  return (
    <div className="relative w-full h-full flex flex-col justify-start bg-gray-50 overflow-y-auto no-scrollbar pb-10">
      {/* Hero Section with Masking & Overlay */}
      <div className="relative w-full h-[360px] overflow-hidden shrink-0">
        <div className="absolute inset-0 z-10 bg-gradient-to-t from-gray-50 via-transparent to-transparent"></div>
        <img
          alt="Premium hair salon interior"
          className="w-full h-full object-cover grayscale-[15%] sepia-[5%] brightness-90 transition-transform duration-1000"
          src="https://lh3.googleusercontent.com/aida-public/AB6AXuAP086t5iiHTy08RQeY1irQb0JrRySmPFpVDmC1Vg5aj_W_TUhG-ISJ4jGiB8dVYTh_p0D375GMgYr8799yH7U4zftnHqz2-tVZtpY1Dlr8fwObU3e_sANr5SMDH1NSufnYk2uL2FBuxdKp5VZqBd5kMZMkoUGRmKUoutpJP5nizvBCN8cCeISuH17UQuq1OYQmhRDqKdrqpYcs9PoyJ3cYbdC0r9-UKHsZ3Aw-eD5cQ1xQOYNH22DkfC4Xgo1Xt-YejI0X-lawo1o"
          referrerPolicy="no-referrer"
        />
        <div className="absolute top-6 left-6 z-20 flex items-center gap-2">
          {mode !== 'welcome' && (
            <button
              onClick={() => handleSwitchMode('welcome')}
              className="p-1 px-2 text-white bg-black/40 backdrop-blur-md rounded-full hover:bg-black/60 transition-colors mr-1 cursor-pointer"
            >
              <ArrowLeft className="w-5 h-5 text-white inline-block" />
            </button>
          )}
          <h1 className="font-serif text-3xl text-black font-bold tracking-tighter">Hairmap</h1>
        </div>
      </div>

      {/* Onboarding Content Sheet */}
      <div className="flex-1 w-full max-w-md px-5 -mt-24 relative z-30">
        <div className="bg-white p-6 rounded-2xl shadow-xl border border-gray-100/50 animate-fade-in">
          
          {/* Role Segment Toggle */}
          <div className="flex bg-neutral-100 p-1 rounded-xl mb-6 border border-neutral-200">
            <button
              type="button"
              onClick={() => {
                setRole('customer');
                setMode('welcome');
                setError('');
              }}
              className={`flex-1 py-1.5 text-xs font-extrabold rounded-lg transition-all cursor-pointer ${
                role === 'customer'
                  ? 'bg-white text-black shadow-xs'
                  : 'text-neutral-500 hover:text-black'
              }`}
            >
              🙋‍♀️ 我是顧客
            </button>
            <button
              type="button"
              onClick={() => {
                setRole('stylist');
                setMode('welcome');
                setError('');
              }}
              className={`flex-1 py-1.5 text-xs font-extrabold rounded-lg transition-all cursor-pointer ${
                role === 'stylist'
                  ? 'bg-neutral-950 text-white shadow-xs'
                  : 'text-neutral-500 hover:text-black'
              }`}
            >
              ✂️ 髮型師工作台
            </button>
          </div>

          {/* Welcome Screen */}
          {mode === 'welcome' && (
            role === 'customer' ? (
              <div className="space-y-6">
                <header className="mb-6 text-center">
                  <h2 className="text-2xl font-bold text-gray-900 mb-2">歡迎來到 Hairmap</h2>
                  <p className="text-sm text-gray-500 font-normal">探索頂尖設計師，打造您的專屬造型</p>
                </header>

                {/* Action cluster */}
                <div className="space-y-4">
                  {/* Primary Registration */}
                  <button
                    onClick={() => handleSwitchMode('register')}
                    className="w-full h-14 bg-black text-white hover:bg-neutral-800 font-semibold text-sm rounded-xl shadow-md transition-all active:scale-[0.98] flex items-center justify-center gap-2 cursor-pointer"
                  >
                    註冊新帳號
                  </button>

                  {/* bypass login */}
                  <button
                    onClick={() => onStart()}
                    className="w-full h-12 bg-gray-50 border border-gray-100 hover:bg-gray-100 text-gray-700 font-semibold text-xs rounded-xl transition-all active:scale-[0.98] flex items-center justify-center gap-2 cursor-pointer"
                  >
                    直接以訪客身分體驗
                  </button>

                  {/* Social options divider */}
                  <div className="flex items-center gap-3 py-1">
                    <div className="flex-1 h-[1px] bg-gray-200"></div>
                    <span className="text-[10px] text-gray-400 font-bold uppercase tracking-wider">或透過以下方式繼續</span>
                    <div className="flex-1 h-[1px] bg-gray-200"></div>
                  </div>

                  {/* Social sign up button grid */}
                  <div className="grid grid-cols-2 gap-3">
                    <button
                      onClick={() => onStart({ nickname: 'Google 使用者', email: 'google.guest@hairmap.com' })}
                      className="flex items-center justify-center gap-2 h-12 border border-gray-200 rounded-xl text-xs font-semibold text-gray-700 hover:bg-gray-50 transition-colors active:scale-[0.98] cursor-pointer"
                    >
                      <svg className="w-4 h-4 flex-shrink-0" viewBox="0 0 24 24">
                        <path
                          d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                          fill="#4285F4"
                        />
                        <path
                          d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                          fill="#34A853"
                        />
                        <path
                          d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"
                          fill="#FBBC05"
                        />
                        <path
                          d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 12-4.53z"
                          fill="#EA4335"
                        />
                      </svg>
                      <span>Google</span>
                    </button>
                    <button
                      onClick={() => onStart({ nickname: 'Apple 會員', email: 'apple.member@hairmap.com' })}
                      className="flex items-center justify-center gap-2 h-12 border border-gray-200 rounded-xl text-xs font-semibold text-gray-700 hover:bg-gray-50 transition-colors active:scale-[0.98] cursor-pointer"
                    >
                      <svg className="w-4 h-4 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.81-3.12 1.87-2.38 5.98.48 7.13-.6 1.48-1.39 2.94-2.53 4.07zM12.03 7.25c-.02-2.23 1.76-4.07 3.9-4.25.3 2.51-2.05 4.54-3.9 4.25z" />
                      </svg>
                      <span>Apple</span>
                    </button>
                  </div>

                  {/* Secondary login bypass */}
                  <div className="pt-4 text-center">
                    <p className="text-sm text-gray-500">
                      已經有帳號了嗎？{' '}
                      <button
                        type="button"
                        onClick={() => handleSwitchMode('login')}
                        className="text-amber-800 font-semibold hover:underline underline-offset-4 bg-transparent border-none p-0 cursor-pointer"
                      >
                        登入
                      </button>
                    </p>
                  </div>
                </div>
              </div>
            ) : (
              <div className="space-y-6">
                <header className="mb-6 text-center">
                  <h2 className="text-2xl font-bold text-neutral-900 mb-2">髮型師專業管理工作台</h2>
                  <p className="text-xs text-neutral-500 font-sans leading-relaxed">
                    在線管理預約排程，實時進行顧客一對一諮詢對話，快速設置 Supabase blocked_slots 忙碌檔期與修改名片作品集。
                  </p>
                </header>

                <div className="space-y-4">
                  {/* Primary Stylist Login */}
                  <button
                    onClick={() => handleSwitchMode('login')}
                    className="w-full h-14 bg-black text-white hover:bg-neutral-800 font-semibold text-sm rounded-xl shadow-md transition-all active:scale-[0.98] flex items-center justify-center gap-2 cursor-pointer"
                  >
                    髮型師電子郵箱登入
                  </button>

                  {/* Quick Tryout / Simulated Login button */}
                  <button
                    type="button"
                    onClick={() => {
                      onStart({ nickname: 'Master Leo', email: 'leo@hairmap.com' }, 'stylist');
                    }}
                    className="w-full h-12 bg-amber-50 border border-amber-200 hover:bg-amber-100 text-amber-900 font-bold text-xs rounded-xl transition-all active:scale-[0.98] flex items-center justify-center gap-2 cursor-pointer"
                  >
                    ⚡️ 快速體驗登入 (預定設 Master Leo)
                  </button>

                  {/* Regular Stylist Register */}
                  <button
                    type="button"
                    onClick={() => handleSwitchMode('register')}
                    className="w-full h-12 bg-neutral-100 border border-neutral-200 hover:bg-neutral-200/60 text-neutral-700 font-semibold text-xs rounded-xl transition-all active:scale-[0.98] flex items-center justify-center gap-2 cursor-pointer"
                  >
                    註冊創立髮型師帳號
                  </button>
                </div>
              </div>
            )
          )}

          {/* Registration Mode */}
          {mode === 'register' && (
            <form onSubmit={handleRegisterSubmit} className="space-y-4 animate-fade-in">
              <header className="mb-4 text-center">
                <h2 className="text-xl font-bold text-gray-900">歡迎註冊新帳號</h2>
                <p className="text-xs text-gray-500 mt-1">請填寫下方資料，完成您在 Hairmap 的專屬帳號</p>
              </header>

              {error && (
                <div className="flex items-center gap-2 p-3 bg-rose-50 border border-rose-100 rounded-xl text-rose-700 text-xs">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{error}</span>
                </div>
              )}

              {/* Nickname / Stylist Professional Nickname */}
              <div className="space-y-1">
                <label className="text-[11px] font-bold text-gray-400 uppercase tracking-wider">
                  {role === 'stylist' ? '髮型師專業暱稱 (暱稱)' : '使用者暱稱'}
                </label>
                <div className="flex items-center bg-gray-50 border border-gray-150 rounded-xl p-3 focus-within:ring-1 focus-within:ring-black focus-within:border-black transition-all">
                  <User className="w-4 h-4 text-gray-400 mr-2.5 shrink-0" />
                  <input
                    type="text"
                    value={nickname}
                    onChange={(e) => setNickname(e.target.value)}
                    className="w-full bg-transparent border-none p-0 text-sm focus:outline-none focus:ring-0 text-gray-800 placeholder-gray-400"
                    placeholder={role === 'stylist' ? '例如：Leo 老師' : '例如：王小明'}
                  />
                </div>
              </div>

              {/* Stylist Professional Title */}
              {role === 'stylist' && (
                <div className="space-y-1 text-left">
                  <label className="text-[11px] font-bold text-gray-400 uppercase tracking-wider block">髮型師專業職稱</label>
                  <div className="flex items-center bg-gray-50 border border-gray-150 rounded-xl p-3 focus-within:ring-1 focus-within:ring-black focus-within:border-black transition-all">
                    <User className="w-4 h-4 text-gray-400 mr-2.5 shrink-0 animate-pulse" />
                    <input
                      type="text"
                      value={stylistTitle}
                      onChange={(e) => setStylistTitle(e.target.value)}
                      className="w-full bg-transparent border-none p-0 text-sm focus:outline-none focus:ring-0 text-gray-800 placeholder-gray-400"
                      placeholder="例如：首席名店設計師 / 燙髮專家"
                    />
                  </div>
                </div>
              )}

              {/* Email */}
              <div className="space-y-1">
                <label className="text-[11px] font-bold text-gray-400 uppercase tracking-wider">電子郵箱</label>
                <div className="flex items-center bg-gray-50 border border-gray-150 rounded-xl p-3 focus-within:ring-1 focus-within:ring-black focus-within:border-black transition-all">
                  <Mail className="w-4 h-4 text-gray-400 mr-2.5 shrink-0" />
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full bg-transparent border-none p-0 text-sm focus:outline-none focus:ring-0 text-gray-800 placeholder-gray-400"
                    placeholder="name@example.com"
                  />
                </div>
              </div>

              {/* Password */}
              <div className="space-y-1">
                <label className="text-[11px] font-bold text-gray-400 uppercase tracking-wider">設定密碼</label>
                <div className="flex items-center bg-gray-50 border border-gray-150 rounded-xl p-3 focus-within:ring-1 focus-within:ring-black focus-within:border-black transition-all">
                  <Lock className="w-4 h-4 text-gray-400 mr-2.5 shrink-0" />
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full bg-transparent border-none p-0 text-sm focus:outline-none focus:ring-0 text-gray-800 placeholder-gray-400"
                    placeholder="請輸入密碼（至少 6 位字元）"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="text-gray-400 hover:text-black transition-colors"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Confirm Password */}
              <div className="space-y-1">
                <label className="text-[11px] font-bold text-gray-400 uppercase tracking-wider">確認密碼</label>
                <div className="flex items-center bg-gray-50 border border-gray-150 rounded-xl p-3 focus-within:ring-1 focus-within:ring-black focus-within:border-black transition-all">
                  <Lock className="w-4 h-4 text-gray-400 mr-2.5 shrink-0" />
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    className="w-full bg-transparent border-none p-0 text-sm focus:outline-none focus:ring-0 text-gray-800 placeholder-gray-400"
                    placeholder="請再次輸入密碼二物確認"
                  />
                </div>
              </div>

              {/* Submit trigger */}
              <button
                type="submit"
                disabled={isLoading}
                className="w-full h-14 bg-black text-white hover:bg-neutral-800 font-semibold text-sm rounded-xl shadow-md transition-all active:scale-[0.98] flex items-center justify-center gap-2 cursor-pointer mt-4"
              >
                {isLoading ? (
                  <span className="flex items-center gap-2">
                    <svg className="animate-spin h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    <span>帳號建立中...</span>
                  </span>
                ) : (
                  <span>註冊帳號並探索環境</span>
                )}
              </button>

              <div className="text-center pt-2">
                <button
                  type="button"
                  onClick={() => handleSwitchMode('login')}
                  className="text-xs text-gray-500 hover:text-black font-semibold"
                >
                  已經有帳號？跳轉登入
                </button>
              </div>
            </form>
          )}

          {/* Login Mode */}
          {mode === 'login' && (
            <form onSubmit={handleLoginSubmit} className="space-y-4 animate-fade-in">
              <header className="mb-4 text-center">
                <h2 className="text-xl font-bold text-gray-900">會員登入</h2>
                <p className="text-xs text-gray-500 mt-1">登入您的帳號，預約最契合的明星設計師</p>
              </header>

              {error && (
                <div className="flex items-center gap-2 p-3 bg-rose-50 border border-rose-100 rounded-xl text-rose-700 text-xs">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{error}</span>
                </div>
              )}

              {/* Email */}
              <div className="space-y-1">
                <label className="text-[11px] font-bold text-gray-400 uppercase tracking-wider">電子郵箱</label>
                <div className="flex items-center bg-gray-50 border border-gray-150 rounded-xl p-3 focus-within:ring-1 focus-within:ring-black focus-within:border-black transition-all">
                  <Mail className="w-4 h-4 text-gray-400 mr-2.5 shrink-0" />
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full bg-transparent border-none p-0 text-sm focus:outline-none focus:ring-0 text-gray-800 placeholder-gray-400"
                    placeholder="name@example.com"
                  />
                </div>
              </div>

              {/* Password */}
              <div className="space-y-1">
                <div className="flex justify-between items-center">
                  <label className="text-[11px] font-bold text-gray-400 uppercase tracking-wider">輸入密碼</label>
                  <button
                    type="button"
                    onClick={() => alert('已將密碼重設郵件發送至您的模擬信箱！')}
                    className="text-[11px] text-amber-800 font-semibold hover:underline bg-transparent border-none cursor-pointer p-0"
                  >
                    忘記密碼？
                  </button>
                </div>
                <div className="flex items-center bg-gray-50 border border-gray-150 rounded-xl p-3 focus-within:ring-1 focus-within:ring-black focus-within:border-black transition-all">
                  <Lock className="w-4 h-4 text-gray-400 mr-2.5 shrink-0" />
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full bg-transparent border-none p-0 text-sm focus:outline-none focus:ring-0 text-gray-800 placeholder-gray-400"
                    placeholder="請輸入密碼"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="text-gray-400 hover:text-black transition-colors"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Submit trigger */}
              <button
                type="submit"
                disabled={isLoading}
                className="w-full h-14 bg-black text-white hover:bg-neutral-800 font-semibold text-sm rounded-xl shadow-md transition-all active:scale-[0.98] flex items-center justify-center gap-2 cursor-pointer mt-4"
              >
                {isLoading ? (
                  <span className="flex items-center gap-2">
                    <svg className="animate-spin h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    <span>登入驗證中...</span>
                  </span>
                ) : (
                  <span>登入並探索環境</span>
                )}
              </button>

              <div className="text-center pt-2">
                <button
                  type="button"
                  onClick={() => handleSwitchMode('register')}
                  className="text-xs text-gray-500 hover:text-black font-semibold"
                >
                  還沒有帳號嗎？申請註冊
                </button>
              </div>
            </form>
          )}

          {/* Footer disclaimer */}
          <footer className="mt-8 text-center">
            <p className="text-[10px] text-gray-400 leading-tight">
              繼續使用即代表您同意 Hairmap 的
              <br />
              <button onClick={() => alert('服務條款')} className="underline hover:text-gray-600 bg-transparent p-0 border-none cursor-pointer">
                服務條款
              </button>{' '}
              與{' '}
              <button onClick={() => alert('隱私權政策')} className="underline hover:text-gray-600 bg-transparent p-0 border-none cursor-pointer">
                隱私權政策
              </button>
            </p>
          </footer>
        </div>
      </div>

      {/* Floating radial gradient blur decor */}
      <div className="fixed bottom-0 left-0 w-full h-32 pointer-events-none opacity-10 z-0">
        <div className="absolute bottom-4 -left-8 w-48 h-48 bg-amber-500 rounded-full blur-3xl"></div>
        <div className="absolute -bottom-8 -right-8 w-64 h-64 bg-black rounded-full blur-3xl"></div>
      </div>
    </div>
  );
}
