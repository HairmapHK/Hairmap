import React, { useState } from 'react';
import { salonsData, stylistsData } from '../data';
import { 
  Search, SlidersHorizontal, MapPin, Star, Bookmark, Phone, 
  Clock, ChevronDown, Check, X, RotateCcw, Sparkles 
} from 'lucide-react';
import { Salon, Stylist } from '../types';

interface DiscoveryProps {
  onSelectStylist: (id: string) => void;
  onSelectSalon?: (id: string) => void;
}

// Salon id to stylist id mapper for realistic transition flows
const salonLeadStylistMap: Record<string, string> = {
  's1': 'master-leo',
  's2': 'alex-chen',
  's3': 'sarah-lin',
  's4': 'jessica-ho'
};

export default function Discovery({ onSelectStylist, onSelectSalon }: DiscoveryProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [savedSalons, setSavedSalons] = useState<Record<string, boolean>>({});

  // Filter Dropdowns and Selections
  const [openFilter, setOpenFilter] = useState<'地區' | '髮型風格' | '價格範圍' | '評分' | null>(null);
  
  // Specific Filter Selections
  const [selectedDistrict, setSelectedDistrict] = useState<string | null>(null);
  const [selectedStyle, setSelectedStyle] = useState<string | null>(null);
  const [selectedPrice, setSelectedPrice] = useState<string | null>(null);
  const [selectedRating, setSelectedRating] = useState<string | null>(null);

  // Filter option arrays
  const filterOptions = ['地區', '髮型風格', '價格範圍', '評分'] as const;
  
  const districts = ['尖沙咀', '中環', '銅鑼灣', '旺角'];
  const styles = ['歐美染髮', '手刷染', '男士理髮', '漸層推剪', '韓式燙髮', '縮毛矯正', '女神大波浪', '線條感挑染'];
  const prices = ['HK$600以下', 'HK$600 - HK$1200', 'HK$1200以上'];
  const ratings = ['4.9星以上', '4.8星以上', '4.7星以上'];

  const toggleBookmark = (e: React.MouseEvent, id: string) => {
    e.stopPropagation();
    setSavedSalons(prev => ({
      ...prev,
      [id]: !prev[id]
    }));
  };

  const handlePillClick = (opt: '地區' | '髮型風格' | '價格範圍' | '評分') => {
    setOpenFilter(openFilter === opt ? null : opt);
  };

  const clearAllFilters = () => {
    setSelectedDistrict(null);
    setSelectedStyle(null);
    setSelectedPrice(null);
    setSelectedRating(null);
    setOpenFilter(null);
  };

  const isAnyFilterActive = !!(selectedDistrict || selectedStyle || selectedPrice || selectedRating);

  // Dynamic filter lists for Salons
  const filteredSalons = salonsData.filter(salon => {
    // Search Term match
    const matchesSearch = searchTerm === '' || 
      salon.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      salon.location.toLowerCase().includes(searchTerm.toLowerCase()) ||
      salon.tags.some(t => t.toLowerCase().includes(searchTerm.toLowerCase()));
      
    if (!matchesSearch) return false;
    
    // District match
    if (selectedDistrict && !salon.location.includes(selectedDistrict)) return false;
    
    // Style match
    if (selectedStyle && !salon.tags.some(t => t.includes(selectedStyle))) return false;
    
    // Price match
    if (selectedPrice) {
      if (selectedPrice === 'HK$600以下' && salon.startPrice > 600) return false;
      if (selectedPrice === 'HK$600 - HK$1200' && (salon.startPrice < 600 || salon.startPrice > 1200)) return false;
      if (selectedPrice === 'HK$1200以上' && salon.startPrice < 1200) return false;
    }
    
    // Rating match
    if (selectedRating) {
      const minRating = parseFloat(selectedRating);
      if (salon.rating < minRating) return false;
    }
    
    return true;
  });

  // Dynamic filter lists for Stylists
  const filteredStylists = stylistsData.filter(sty => {
    // Search term match
    const matchesSearch = searchTerm === '' ||
      sty.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      sty.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      sty.specialties.some(sp => sp.toLowerCase().includes(searchTerm.toLowerCase()));
      
    if (!matchesSearch) return false;
    
    // District check mapped to stylist profiles
    if (selectedDistrict) {
      if (selectedDistrict === '尖沙咀' && sty.id !== 'master-leo') return false;
      if (selectedDistrict === '中環' && sty.id !== 'alex-chen') return false;
      if (selectedDistrict === '銅鑼灣' && sty.id !== 'sarah-lin') return false;
      if (selectedDistrict === '旺角' && sty.id !== 'jessica-ho') return false;
    }
    
    // Style match
    if (selectedStyle && !sty.specialties.some(sp => sp.includes(selectedStyle))) return false;
    
    // Rating match
    if (selectedRating) {
      const minRating = parseFloat(selectedRating);
      if (sty.rating < minRating) return false;
    }
    
    return true;
  });

  return (
    <div className="w-full h-full bg-[#fdfdfd] text-gray-900 overflow-y-auto no-scrollbar pb-24 relative">
      
      {/* Search Header Bar */}
      <header className="bg-white/90 backdrop-blur-md w-full sticky top-0 z-40 transition-all duration-300 border-b border-gray-100/80 shadow-xs">
        <div className="flex justify-between items-center px-5 py-4 w-full">
          <div className="flex items-center gap-2">
            <img 
              alt="Hairmap Logo" 
              className="w-8 h-8 rounded-full border border-gray-100 shrink-0" 
              src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0MCIgaGVpZ2h0PSI0MCIgdmlld0JveD0iMCAwIDQwIDQwIj48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIyMCIgZmlsbD0iIzAwMCIvPjx0ZXh0IHg9IjIwIiB5PSIyNSIgZmlsbD0iI2ZmZiIgZm9udC1mYW1pbHk9InNlcmlmIiBmb250LXNpemU9IjIyIiBmb250LXdlaWdodD0iYm9sZCIgdGV4dC1hbmNob3I9Im1pZGRsZSI+SDwvdGV4dD48L3N2Zz4="
            />
            <h1 className="font-serif text-3xl font-bold tracking-tighter text-black">Hairmap</h1>
          </div>
          <div className="flex items-center gap-3">
            <button 
              onClick={clearAllFilters}
              disabled={!isAnyFilterActive}
              className={`p-2 rounded-full cursor-pointer transition-colors ${
                isAnyFilterActive ? 'text-amber-600 hover:bg-amber-50' : 'text-gray-300 pointer-events-none'
              }`}
              title="重設所有篩選"
            >
              <RotateCcw className="w-5 h-5" />
            </button>
            <button className="text-gray-500 hover:text-black transition-colors cursor-pointer relative">
              <span className="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full"></span>
              <SlidersHorizontal className="w-5 h-5" />
            </button>
          </div>
        </div>
      </header>

      {/* Main Filter & Search Container */}
      <section className="bg-white px-5 pt-3 pb-3 sticky top-[60px] z-35 border-b border-gray-100 space-y-3.5 shadow-2xs">
        
        {/* Search input bar */}
        <div className="flex items-center gap-3 bg-gray-50 rounded-full px-4 py-3 border border-gray-150/60 focus-within:border-black transition-all">
          <Search className="w-4.5 h-4.5 text-gray-400 shrink-0" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="flex-1 bg-transparent border-none focus:outline-none focus:ring-0 text-gray-800 font-sans text-sm p-0 placeholder-gray-400"
            placeholder="搜尋沙龍名稱、特點風格、尖沙咀地區..."
          />
          {searchTerm && (
            <button 
              onClick={() => setSearchTerm('')}
              className="text-gray-400 hover:text-black transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>

        {/* Dynamic Filter Pills Row */}
        <div className="flex gap-2 overflow-x-auto no-scrollbar py-0.5">
          {filterOptions.map((opt) => {
            // Check if this specific filter has an active value
            let activeValue: string | null = null;
            if (opt === '地區') activeValue = selectedDistrict;
            if (opt === '髮型風格') activeValue = selectedStyle;
            if (opt === '價格範圍') activeValue = selectedPrice;
            if (opt === '評分') activeValue = selectedRating;

            const isOpen = openFilter === opt;
            const isSelected = activeValue !== null;

            return (
              <button
                key={opt}
                onClick={() => handlePillClick(opt)}
                className={`flex items-center gap-1 whitespace-nowrap px-3.5 py-1.5 rounded-full text-[11px] font-bold transition-all active:scale-95 cursor-pointer ${
                  isOpen
                    ? 'bg-neutral-900 text-white shadow-xs'
                    : isSelected 
                      ? 'bg-amber-500 text-white shadow-xs'
                      : 'bg-neutral-100 text-neutral-600 hover:bg-neutral-200 border border-transparent'
                }`}
              >
                <span>{isSelected ? `${opt}: ${activeValue}` : opt}</span>
                <ChevronDown className={`w-3.5 h-3.5 shrink-0 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
              </button>
            );
          })}
        </div>

        {/* --- DYNAMIC COLLAPSIBLE DROP-DOWN KEYWORDS KEYPADS --- */}
        {openFilter && (
          <div className="border border-neutral-150 bg-neutral-55/40 rounded-2xl p-3.5 space-y-3.5 animate-fade-in text-slate-800">
            <div className="flex justify-between items-center text-xs">
              <span className="font-bold text-gray-500 font-sans uppercase tracking-wider flex items-center gap-1">
                <Sparkles className="w-3.5 h-3.5 text-amber-500" />
                篩選 {openFilter} 關鍵字
              </span>
              <button 
                type="button"
                onClick={() => {
                  if (openFilter === '地區') setSelectedDistrict(null);
                  if (openFilter === '髮型風格') setSelectedStyle(null);
                  if (openFilter === '價格範圍') setSelectedPrice(null);
                  if (openFilter === '評分') setSelectedRating(null);
                }}
                className="text-[10px] text-neutral-400 hover:text-rose-500 font-bold transition-colors"
              >
                重設此項
              </button>
            </div>

            {/* District List choices */}
            {openFilter === '地區' && (
              <div className="flex flex-wrap gap-2">
                {districts.map((d) => {
                  const isSelected = selectedDistrict === d;
                  return (
                    <button
                      key={d}
                      onClick={() => {
                        setSelectedDistrict(isSelected ? null : d);
                        setOpenFilter(null); // auto close for immediate impact
                      }}
                      className={`text-xs font-semibold px-3 py-1.5 rounded-xl border cursor-pointer transition-all ${
                        isSelected 
                          ? 'bg-black text-white border-black shadow-sm' 
                          : 'bg-white text-gray-700 border-gray-200 hover:bg-neutral-150'
                      }`}
                    >
                      {d} {isSelected && '✓'}
                    </button>
                  );
                })}
              </div>
            )}

            {/* Style List choices */}
            {openFilter === '髮型風格' && (
              <div className="flex flex-wrap gap-2">
                {styles.map((st) => {
                  const isSelected = selectedStyle === st;
                  return (
                    <button
                      key={st}
                      onClick={() => {
                        setSelectedStyle(isSelected ? null : st);
                        setOpenFilter(null); // auto close
                      }}
                      className={`text-xs font-semibold px-3 py-1.5 rounded-xl border cursor-pointer transition-all ${
                        isSelected 
                          ? 'bg-black text-white border-black shadow-sm' 
                          : 'bg-white text-gray-700 border-gray-200 hover:bg-neutral-150'
                      }`}
                    >
                      {st} {isSelected && '✓'}
                    </button>
                  );
                })}
              </div>
            )}

            {/* Price list choices */}
            {openFilter === '價格範圍' && (
              <div className="flex flex-col gap-1.5">
                {prices.map((p) => {
                  const isSelected = selectedPrice === p;
                  return (
                    <button
                      key={p}
                      onClick={() => {
                        setSelectedPrice(isSelected ? null : p);
                        setOpenFilter(null); // auto close
                      }}
                      className={`w-full text-left text-xs font-semibold p-2.5 px-3.5 rounded-xl border cursor-pointer transition-all flex justify-between items-center ${
                        isSelected 
                          ? 'bg-black text-white border-black shadow-sm' 
                          : 'bg-white bg-opacity-70 text-gray-700 border-gray-200 hover:bg-neutral-150'
                      }`}
                    >
                      <span>{p}</span>
                      {isSelected && <Check className="w-3.5 h-3.5 text-white stroke-[2.5]" />}
                    </button>
                  );
                })}
              </div>
            )}

            {/* Ratings choices */}
            {openFilter === '評分' && (
              <div className="flex flex-col gap-1.5">
                {ratings.map((r) => {
                  const isSelected = selectedRating === r;
                  return (
                    <button
                      key={r}
                      onClick={() => {
                        setSelectedRating(isSelected ? null : r);
                        setOpenFilter(null); // auto close
                      }}
                      className={`w-full text-left text-xs font-semibold p-2.5 px-3.5 rounded-xl border cursor-pointer transition-all flex justify-between items-center ${
                        isSelected 
                          ? 'bg-black text-white border-black shadow-sm' 
                          : 'bg-white bg-opacity-70 text-gray-700 border-gray-200 hover:bg-neutral-150'
                      }`}
                    >
                      <span className="flex items-center gap-1">
                        <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
                        {r}
                      </span>
                      {isSelected && <Check className="w-3.5 h-3.5 text-white stroke-[2.5]" />}
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* Selected feedback tags row for easy dismissing */}
        {isAnyFilterActive && (
          <div className="flex flex-wrap items-center gap-1.5 pt-1 text-[10px]">
            <span className="text-gray-400 mr-1 font-bold uppercase">目前篩選:</span>
            {selectedDistrict && (
              <span className="bg-amber-100 text-amber-900 font-bold px-2 py-0.5 rounded flex items-center gap-1">
                {selectedDistrict}
                <X className="w-3 h-3 hover:text-red-500 cursor-pointer" onClick={() => setSelectedDistrict(null)} />
              </span>
            )}
            {selectedStyle && (
              <span className="bg-amber-100 text-amber-900 font-bold px-2 py-0.5 rounded flex items-center gap-1">
                {selectedStyle}
                <X className="w-3 h-3 hover:text-red-500 cursor-pointer" onClick={() => setSelectedStyle(null)} />
              </span>
            )}
            {selectedPrice && (
              <span className="bg-amber-100 text-amber-900 font-bold px-2 py-0.5 rounded flex items-center gap-1">
                {selectedPrice}
                <X className="w-3 h-3 hover:text-red-500 cursor-pointer" onClick={() => setSelectedPrice(null)} />
              </span>
            )}
            {selectedRating && (
              <span className="bg-amber-100 text-amber-900 font-bold px-2 py-0.5 rounded flex items-center gap-1">
                ★ {selectedRating}
                <X className="w-3 h-3 hover:text-red-500 cursor-pointer" onClick={() => setSelectedRating(null)} />
              </span>
            )}
            <button 
              onClick={clearAllFilters}
              className="text-gray-500 hover:text-rose-600 font-bold ml-1.5 underline"
            >
              清除全部
            </button>
          </div>
        )}

      </section>

      {/* Popular Stylists horizontal sliding carousel */}
      <section className="mt-5">
        <div className="px-5 flex justify-between items-end mb-3">
          <h2 className="font-bold text-lg text-gray-900 font-sans tracking-tight flex items-center gap-1">
            <Sparkles className="w-4.5 h-4.5 text-amber-500 fill-amber-300" />
            <span>精選推薦髮型設計師</span>
          </h2>
          <span className="text-[11px] text-gray-400 font-mono font-bold uppercase">
            {filteredStylists.length}位
          </span>
        </div>

        {filteredStylists.length > 0 ? (
          <div className="flex gap-4 overflow-x-auto no-scrollbar px-5 pb-2">
            {filteredStylists.map((sty) => (
              <div 
                key={sty.id} 
                onClick={() => onSelectStylist(sty.id)}
                className="flex-none w-36 space-y-2 group cursor-pointer"
              >
                <div className="aspect-square rounded-2xl overflow-hidden relative border border-gray-100/50 shadow-2xs group-hover:shadow transition-all">
                  <img
                    alt={sty.name}
                    className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                    src={sty.avatar}
                    referrerPolicy="no-referrer"
                  />
                  <div className="absolute top-2 right-2 bg-white/95 px-1.5 py-0.5 rounded-full flex items-center gap-0.5 shadow-2xs border border-gray-100">
                    <Star className="w-2.5 h-2.5 fill-amber-400 text-amber-400 shrink-0" />
                    <span className="text-[10px] font-bold text-gray-800">{sty.rating}</span>
                  </div>
                </div>
                <div>
                  <h3 className="font-bold text-sm text-gray-900 truncate leading-tight group-hover:text-amber-800 transition-colors">{sty.name}</h3>
                  <p className="text-[11px] text-gray-500 font-normal truncate mt-0.5">{sty.title}</p>
                  
                  {/* Specialties tag inside popular */}
                  <div className="flex gap-1 overflow-hidden mt-1 max-w-full">
                    {sty.specialties.slice(0, 1).map((spec) => (
                      <span key={spec} className="text-[8px] bg-neutral-100 text-neutral-500 px-1 py-0.2 rounded font-bold whitespace-nowrap">
                        {spec}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="mx-5 p-6 rounded-2xl text-center bg-gray-50 border border-dashed border-gray-200">
            <p className="text-xs text-gray-400">目前沒有相符的設計師，請更換篩選關鍵字</p>
          </div>
        )}
      </section>

      {/* Recommended Salons Vertical List */}
      <section className="mt-8 px-5 space-y-4">
        <div className="flex justify-between items-center">
          <h2 className="font-bold text-lg text-gray-900 font-sans tracking-tight">為您推薦沙龍</h2>
          <span className="text-xs text-gray-400 font-semibold">{filteredSalons.length} 間可供探索</span>
        </div>

        {filteredSalons.length > 0 ? (
          <div className="space-y-6">
            {filteredSalons.map((salon) => {
              const isSaved = !!savedSalons[salon.id];
              const stylistIdForSalon = salonLeadStylistMap[salon.id] || 'master-leo';
              
              return (
                <div
                  key={salon.id}
                  onClick={() => {
                    if (onSelectSalon) {
                      onSelectSalon(salon.id);
                    }
                  }}
                  className="bg-white rounded-2xl overflow-hidden border border-gray-100 shadow-xs hover:shadow-md transition-all active:scale-[0.99] duration-300 cursor-pointer group"
                >
                  <div className="relative h-48 overflow-hidden bg-gray-100">
                    <img
                      alt={salon.name}
                      className="w-full h-full object-cover select-none transition-transform duration-700 group-hover:scale-102"
                      src={salon.imageUrl}
                      referrerPolicy="no-referrer"
                    />
                    <button
                      onClick={(e) => toggleBookmark(e, salon.id)}
                      className="absolute top-4 right-4 w-10 h-10 bg-white/40 backdrop-blur-md rounded-full flex items-center justify-center text-white border border-white/40 hover:bg-white/60 hover:scale-105 active:scale-95 transition-all cursor-pointer z-10"
                    >
                      <Bookmark className={`w-4 h-4 transition-colors ${isSaved ? 'fill-amber-500 text-amber-500' : 'text-white'}`} />
                    </button>
                    {/* Radial background mask */}
                    <div className="absolute inset-x-0 bottom-0 h-12 bg-gradient-to-t from-black/25 to-transparent"></div>
                  </div>

                  <div className="p-4 space-y-3">
                    <div className="flex justify-between items-start">
                      <div className="space-y-1">
                        <h3 className="font-bold text-base text-gray-900 group-hover:text-amber-800 transition-colors">{salon.name}</h3>
                        <div className="flex items-center gap-1 text-xs text-gray-500 font-normal">
                          <MapPin className="w-3.5 h-3.5 shrink-0 text-amber-600" />
                          <span>{salon.distance}km • {salon.location}</span>
                        </div>
                      </div>
                      <div className="flex items-center gap-1 bg-amber-50 px-2 py-1 rounded-lg border border-amber-100">
                        <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400 shrink-0" />
                        <span className="text-xs font-bold text-gray-800">{salon.rating}</span>
                      </div>
                    </div>

                    <div className="flex flex-wrap gap-1.5">
                      {salon.tags.map((tag) => (
                        <span key={tag} className="px-3 py-1 bg-gray-50 text-gray-600 text-[10px] font-bold rounded-full border border-gray-100/70">
                          #{tag}
                        </span>
                      ))}
                    </div>

                    <div className="pt-3 border-t border-gray-100 flex justify-between items-center">
                      <div className="flex items-center gap-3">
                        <div className="flex items-center gap-1 text-xs text-gray-400">
                          <Clock className="w-3.5 h-3.5 shrink-0" />
                          <span>{salon.openHours}</span>
                        </div>
                        <div className="flex items-center gap-1 text-xs text-gray-400">
                          <Phone className="w-3.5 h-3.5 shrink-0" />
                          <span>{salon.phone}</span>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-[9px] text-gray-400 uppercase tracking-widest leading-none font-semibold">服務起價</p>
                        <p className="font-bold text-sm text-amber-900 mt-1">HK$ {salon.startPrice}</p>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <div className="text-center py-12 rounded-2xl bg-gray-50 border border-dashed border-gray-200">
            <p className="text-sm text-gray-400 font-medium">沒有符合您篩選標準的沙龍</p>
            <button 
              onClick={clearAllFilters}
              className="mt-3 text-xs bg-black text-white hover:bg-neutral-800 font-bold px-4 py-2 rounded-xl transition-all shadow-xs"
            >
              清除所有條件以查看推薦
            </button>
          </div>
        )}
      </section>

    </div>
  );
}
