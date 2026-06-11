export interface Service {
  id: string;
  name: string;
  category: string;
  duration: number; // in minutes
  description: string;
  price: number;
}

export interface Review {
  id: string;
  reviewerName: string;
  reviewerAvatar: string;
  text: string;
  stars: number;
  timeAgo: string;
  images?: string[];
}

export interface Stylist {
  id: string;
  name: string;
  title: string;
  rating: number;
  reviewsCount: number;
  languages: string;
  experience: string;
  specialties: string[];
  avatar: string;
  works: { id: string; title: string; imageUrl: string }[];
  services: Service[];
  reviews: Review[];
  bio?: string;
  price?: number;
}

export interface Salon {
  id: string;
  name: string;
  location: string;
  distance: number; // in km
  rating: number;
  tags: string[];
  openHours: string;
  phone: string;
  startPrice: number;
  imageUrl: string;
}

export interface Booking {
  id: string;
  salonName: string;
  stylistName: string;
  date: string;
  timeSlot: string;
  serviceName: string;
  price: number;
  status: 'upcoming' | 'history';
}

export interface ChatMessage {
  id: string;
  senderId: 'stylist' | 'user';
  senderName: string;
  text: string;
  time: string;
  isSystemAdvice?: boolean;
}

export type ActiveView = 
  | 'onboarding' 
  | 'discovery' 
  | 'inspiration' 
  | 'stylist-profile' 
  | 'salon-profile'
  | 'booking' 
  | 'chat' 
  | 'profile' 
  | 'become-stylist'
  | 'stylist-bookings'
  | 'stylist-chat'
  | 'stylist-schedule'
  | 'stylist-my-profile';

export interface BlockedSlot {
  id: string;
  stylistId: string;
  date: string; // YYYY-MM-DD
  time: string; // HH:MM e.g. "09:00", "12:00"
}

