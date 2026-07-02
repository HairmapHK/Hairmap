export type Profile = {
  id: string;
  display_name: string;
  email: string;
  role: 'customer' | 'stylist';
  stylist_id: string | null;
  avatar_url?: string;
};

export type Stylist = {
  id: string;
  owner_id: string | null;
  salon_id: string;
  district: string;
  location: string;
  name: string;
  title: string;
  rating: number;
  reviews_count: number;
  languages: string;
  experience: string;
  specialties: string[];
  avatar_url: string;
  phone: string;
  instagram_url: string;
  bio: string;
  base_price: number;
  is_active: boolean;
  is_featured: boolean;
  display_order: number;
};

export type ServiceItem = {
  id: string;
  stylist_id: string;
  name: string;
  category: string;
  duration: number;
  description: string;
  price: number;
  is_active?: boolean;
  display_order?: number;
};

export type PortfolioWork = {
  id: string;
  stylist_id: string;
  title: string;
  image_url: string;
  media_kind?: 'photo' | 'video';
  video_url?: string;
  thumbnail_url?: string;
  is_active?: boolean;
  display_order?: number;
};

export type BookingStatus = 'pending' | 'accepted' | 'in_progress' | 'completed' | 'cancelled';
export type BookingAssignmentMode = 'stylist_selected' | 'salon_assigns';

export type Booking = {
  id: string;
  customer_id: string | null;
  stylist_id: string | null;
  salon_id: string;
  salon_brand_id: string | null;
  service_id: string | null;
  salon_name: string;
  stylist_name: string;
  client_name: string;
  client_phone: string;
  booking_date: string;
  start_time: string;
  end_time: string;
  service_name: string;
  price: number;
  status: BookingStatus;
  branch_name: string;
  assignment_mode: BookingAssignmentMode;
  assigned_stylist_id: string | null;
  booking_note: string;
  created_at?: string;
  updated_at?: string;
};

export type ChatMessage = {
  id: string;
  customer_id: string | null;
  stylist_id: string;
  sender_role: 'customer' | 'stylist';
  sender_name: string;
  text: string;
  sent_at: string;
  created_at?: string;
  is_recalled?: boolean;
  recalled_at?: string | null;
};

export type BlockedSlot = {
  id: string;
  stylist_id: string;
  work_date: string;
  start_time: string;
};

export type ApplicationStatus = 'pending' | 'approved' | 'rejected' | 'hidden';

export type StylistApplication = {
  id: string;
  submitted_by: string | null;
  stylist_id: string;
  owner_id: string | null;
  contact_email: string;
  salon_id: string;
  district: string;
  location: string;
  name: string;
  title: string;
  rating: number;
  reviews_count: number;
  languages: string;
  experience: string;
  specialties: string[];
  avatar_url: string;
  phone: string;
  instagram_url: string;
  bio: string;
  base_price: number;
  services_payload: ServiceItem[];
  works_payload: PortfolioWork[];
  status: ApplicationStatus;
  admin_note: string;
  created_at: string;
  updated_at: string;
};

export type ProfileDraft = {
  name: string;
  title: string;
  phone: string;
  district: string;
  location: string;
  basePrice: string;
  bio: string;
  experience: string;
  languages: string;
  avatarURL: string;
  instagramURL: string;
  tags: string[];
  services: ServiceDraft[];
  works: WorkDraft[];
};

export type ServiceDraft = {
  id: string;
  name: string;
  category: string;
  duration: string;
  price: string;
  description: string;
};

export type WorkDraft = {
  id: string;
  title: string;
  imageURL: string;
  mediaKind: 'photo' | 'video';
  videoURL: string;
  thumbnailURL: string;
};
