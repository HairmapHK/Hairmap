export type AdminRole = 'super_admin' | 'admin' | 'moderator';
export type ApplicationStatus = 'pending' | 'approved' | 'rejected' | 'hidden';
export type ReportStatus = 'open' | 'reviewing' | 'resolved' | 'dismissed';
export type EntityType = 'stylist' | 'salon' | 'inspiration' | 'review' | 'message' | 'profile';

export type AdminUser = {
  user_id: string;
  role: AdminRole;
  display_name: string;
};

export type Profile = {
  id: string;
  display_name: string;
  email: string;
  role: string;
  stylist_id: string | null;
  avatar_url: string;
};

export type ServiceItem = {
  id: string;
  stylist_id: string;
  name: string;
  category: string;
  duration: number;
  description: string;
  price: number;
};

export type PortfolioWork = {
  id: string;
  stylist_id: string;
  title: string;
  image_url: string;
  is_active?: boolean;
  display_order?: number;
};

export type SalonWork = {
  id: string;
  salon_id: string;
  title: string;
  image_url: string;
  is_active: boolean;
  display_order: number;
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
  admin_note?: string;
  created_at?: string;
  updated_at?: string;
};

export type Salon = {
  id: string;
  name: string;
  location: string;
  district: string;
  distance: number;
  rating: number;
  tags: string[];
  open_hours: string;
  phone: string;
  instagram_url: string;
  start_price: number;
  image_url: string;
  is_active: boolean;
  is_featured: boolean;
  display_order: number;
  admin_note?: string;
  created_at?: string;
  updated_at?: string;
};

export type StylistApplication = {
  id: string;
  submitted_by: string | null;
  stylist_id: string;
  owner_id: string | null;
  contact_email: string;
  claimed_by: string | null;
  claimed_at: string | null;
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
  reviewed_by: string | null;
  reviewed_at: string | null;
  created_at: string;
  updated_at: string;
};

export type SalonApplication = {
  id: string;
  submitted_by: string | null;
  salon_id: string;
  name: string;
  location: string;
  district: string;
  distance: number;
  rating: number;
  tags: string[];
  open_hours: string;
  phone: string;
  instagram_url: string;
  start_price: number;
  image_url: string;
  works_payload: PortfolioWork[];
  status: ApplicationStatus;
  admin_note: string;
  reviewed_by: string | null;
  reviewed_at: string | null;
  created_at: string;
  updated_at: string;
};

export type InspirationItem = {
  id: string;
  stylist_id: string;
  title: string;
  salon_name: string;
  location: string;
  tags: string[];
  image_url: string;
  category: string;
  created_at: string;
  is_active: boolean;
  is_featured: boolean;
  display_order: number;
  like_count: number;
  comment_count: number;
  share_count: number;
  author_id: string | null;
  author_name: string;
  studio: string;
  media_urls: string[];
  media_kinds: string[];
  face_shape: string;
  hair_type: string;
  specs: string;
  details: string;
  is_user_post: boolean;
};

export type InspirationComment = {
  id: string;
  inspiration_id: string;
  parent_id: string | null;
  author_id: string | null;
  author_name: string;
  author_avatar: string;
  body: string;
  like_count: number;
  is_creator: boolean;
  is_hidden: boolean;
  created_at: string;
  updated_at: string;
};

export type Report = {
  id: string;
  reporter_id: string | null;
  entity_type: EntityType;
  entity_id: string;
  reason: string;
  details: string;
  status: ReportStatus;
  resolved_by: string | null;
  resolved_at: string | null;
  created_at: string;
  updated_at: string;
};

export type HomepageSection = {
  id: string;
  section_key: string;
  title: string;
  layout: string;
  sort_order: number;
  is_active: boolean;
};

export type HomepageItem = {
  id: string;
  section_id: string;
  item_type: 'stylist' | 'salon' | 'inspiration';
  item_id: string;
  title_override: string | null;
  image_url_override: string | null;
  sort_order: number;
  is_featured: boolean;
  is_active: boolean;
};

export type RankingOverride = {
  id: string;
  ranking_key: string;
  item_type: 'stylist' | 'salon';
  item_id: string;
  manual_rank: number | null;
  score_override: number | null;
  is_pinned: boolean;
  is_active: boolean;
  note: string;
};

export type AdminData = {
  profiles: Profile[];
  stylists: Stylist[];
  salons: Salon[];
  services: ServiceItem[];
  works: PortfolioWork[];
  salonWorks: SalonWork[];
  stylistApplications: StylistApplication[];
  salonApplications: SalonApplication[];
  inspirations: InspirationItem[];
  comments: InspirationComment[];
  reports: Report[];
  homepageSections: HomepageSection[];
  homepageItems: HomepageItem[];
  rankingOverrides: RankingOverride[];
};

export type DetailTarget =
  | { kind: 'stylistApplication'; item: StylistApplication }
  | { kind: 'salonApplication'; item: SalonApplication }
  | { kind: 'stylist'; item: Stylist }
  | { kind: 'salon'; item: Salon }
  | { kind: 'inspiration'; item: InspirationItem }
  | { kind: 'report'; item: Report };
