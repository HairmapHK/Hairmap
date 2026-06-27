import { ChangeEvent, FormEvent, ReactNode, useMemo, useState } from 'react';
import {
  ArrowRight,
  BadgeCheck,
  Building2,
  Camera,
  Check,
  ImagePlus,
  Loader2,
  Mail,
  Phone,
  Plus,
  Scissors,
  Send,
  Sparkles,
  Trash2,
  UploadCloud,
  UserRound,
} from 'lucide-react';
import { supabase } from './supabase';

type ApplicationKind = 'stylist' | 'salon';

type ServiceDraft = {
  name: string;
  category: string;
  duration: string;
  price: string;
  description: string;
};

type SubmitState =
  | { status: 'idle' }
  | { status: 'submitting'; message: string }
  | { status: 'success'; applicationID: string; kind: ApplicationKind }
  | { status: 'error'; message: string };

const DEFAULT_STYLIST_TAGS = ['挑染專家', '經典剪髮', '歐美挑染', '漸層推剪', '韓式燙髮', '縮毛矯正', '女神大波浪', '深層護理'];
const DEFAULT_SALON_TAGS = ['歐美染髮', '手刷染', '男士理髮', '日系沙龍', '韓式燙髮', '頭皮護理', 'VIP 包廂', '寵物友善'];
const DEFAULT_FEATURES = ['提供手沖精品咖啡', '獨立包廂空間', '高速 Wi-Fi', '有機染護產品', '頭皮敏感隔離修護', '近港鐵站'];
const DISTRICTS = ['中環', '銅鑼灣', '尖沙咀', '旺角', '荃灣', '觀塘', '元朗', '沙田', '將軍澳', '屯門'];

const initialServices: ServiceDraft[] = [
  { name: '招牌精修剪髮', category: '剪髮', duration: '60', price: '380', description: '包含溝通、洗髮與造型整理' },
  { name: '高級染護服務', category: '染髮', duration: '120', price: '880', description: '按髮質與目標色客製調配' },
];

function App() {
  const [kind, setKind] = useState<ApplicationKind>('stylist');
  const [submitState, setSubmitState] = useState<SubmitState>({ status: 'idle' });

  const [applicantName, setApplicantName] = useState('');
  const [applicantEmail, setApplicantEmail] = useState('');
  const [applicantPhone, setApplicantPhone] = useState('');

  const [stylistName, setStylistName] = useState('');
  const [stylistTitle, setStylistTitle] = useState('');
  const [stylistPhone, setStylistPhone] = useState('');
  const [stylistExperience, setStylistExperience] = useState('5年資歷');
  const [stylistLanguages, setStylistLanguages] = useState('中 / 粵 / 英');
  const [stylistDistrict, setStylistDistrict] = useState('尖沙咀');
  const [stylistWorkplace, setStylistWorkplace] = useState('');
  const [stylistBio, setStylistBio] = useState('');
  const [stylistBasePrice, setStylistBasePrice] = useState('380');
  const [stylistTags, setStylistTags] = useState<string[]>(['挑染專家', '經典剪髮']);
  const [stylistAvatar, setStylistAvatar] = useState<File[]>([]);
  const [stylistWorks, setStylistWorks] = useState<File[]>([]);

  const [salonName, setSalonName] = useState('');
  const [salonLocation, setSalonLocation] = useState('');
  const [salonDistrict, setSalonDistrict] = useState('尖沙咀');
  const [salonPhone, setSalonPhone] = useState('');
  const [salonHours, setSalonHours] = useState('11:00 - 20:00');
  const [salonStartPrice, setSalonStartPrice] = useState('480');
  const [salonIntro, setSalonIntro] = useState('');
  const [salonTags, setSalonTags] = useState<string[]>(['歐美染髮', '手刷染']);
  const [salonFeatures, setSalonFeatures] = useState<string[]>(['高速 Wi-Fi']);
  const [salonCover, setSalonCover] = useState<File[]>([]);
  const [salonWorks, setSalonWorks] = useState<File[]>([]);

  const [customStylistTag, setCustomStylistTag] = useState('');
  const [customSalonTag, setCustomSalonTag] = useState('');
  const [customFeature, setCustomFeature] = useState('');
  const [services, setServices] = useState<ServiceDraft[]>(initialServices);

  const activeTags = kind === 'stylist' ? stylistTags : salonTags;
  const readySummary = useMemo(() => {
    if (kind === 'stylist') {
      return {
        title: stylistName || '未命名髮型師',
        subtitle: `${stylistTitle || '專業髮型師'} · ${stylistDistrict}`,
        photoCount: stylistWorks.length,
      };
    }
    return {
      title: salonName || '未命名沙龍',
      subtitle: `${salonDistrict} · ${salonHours}`,
      photoCount: salonWorks.length,
    };
  }, [kind, stylistName, stylistTitle, stylistDistrict, stylistWorks.length, salonName, salonDistrict, salonHours, salonWorks.length]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitState({ status: 'idle' });

    try {
      validateCommon(applicantName, applicantEmail, applicantPhone);
      if (kind === 'stylist') {
        await submitStylistApplication();
      } else {
        await submitSalonApplication();
      }
    } catch (error) {
      setSubmitState({ status: 'error', message: error instanceof Error ? error.message : '提交失敗，請稍後再試。' });
    }
  }

  async function submitStylistApplication() {
    if (!stylistName.trim()) throw new Error('請填寫髮型師姓名。');
    if (!stylistTitle.trim()) throw new Error('請填寫頭銜職稱。');
    if (!stylistPhone.trim()) throw new Error('請填寫髮型師聯絡電話。');
    if (!stylistBio.trim()) throw new Error('請填寫個人簡介。');
    if (!stylistAvatar.length) throw new Error('請上載一張髮型師頭像。');

    const stylistID = makePublicID('stylist', stylistName);
    const applicationID = makePublicID('stylist-application', stylistName);
    setSubmitState({ status: 'submitting', message: '正在上載頭像與作品照片...' });

    const avatarURL = (await uploadFiles('stylist-avatar', applicationID, stylistAvatar))[0];
    const workURLs = await uploadFiles('stylist-works', applicationID, stylistWorks);
    const normalizedServices = buildServicePayload(stylistID, services);
    const worksPayload = buildWorksPayload(stylistID, workURLs, stylistWorks);
    const normalizedApplicantEmail = applicantEmail.trim().toLowerCase();

    setSubmitState({ status: 'submitting', message: '正在建立髮型師 pending 申請...' });
    const { error } = await supabase.from('stylist_applications').insert({
      id: applicationID,
      submitted_by: null,
      stylist_id: stylistID,
      owner_id: null,
      contact_email: normalizedApplicantEmail,
      salon_id: 'independent-stylist-studio',
      name: stylistName.trim(),
      title: stylistTitle.trim(),
      rating: 5,
      reviews_count: 0,
      languages: stylistLanguages.trim(),
      experience: stylistExperience.trim(),
      specialties: stylistTags,
      avatar_url: avatarURL,
      phone: stylistPhone.trim(),
      bio: stylistBio.trim(),
      base_price: toInt(stylistBasePrice),
      services_payload: normalizedServices,
      works_payload: worksPayload,
      status: 'pending',
      admin_note: [
        '公開申請網站提交：髮型師',
        `聯絡人：${applicantName}`,
        `Email：${normalizedApplicantEmail}`,
        `申請人電話：${applicantPhone}`,
        `髮型師電話：${stylistPhone}`,
        `地區：${stylistDistrict}`,
        `工作室 / 沙龍：${stylistWorkplace || '未提供'}`,
        `作品數量：${workURLs.length}`,
      ].join('\n'),
    });

    if (error) throw error;
    setSubmitState({ status: 'success', applicationID, kind: 'stylist' });
    resetStylistMediaOnly();
  }

  async function submitSalonApplication() {
    if (!salonName.trim()) throw new Error('請填寫沙龍名稱。');
    if (!salonLocation.trim()) throw new Error('請填寫沙龍地址。');
    if (!salonPhone.trim()) throw new Error('請填寫沙龍電話。');
    if (!salonIntro.trim()) throw new Error('請填寫沙龍介紹。');
    if (!salonCover.length) throw new Error('請上載一張沙龍封面照。');

    const salonID = makePublicID('salon', salonName);
    const applicationID = makePublicID('salon-application', salonName);
    setSubmitState({ status: 'submitting', message: '正在上載沙龍封面與環境照片...' });

    const coverURL = (await uploadFiles('salon-cover', applicationID, salonCover))[0];
    const workURLs = await uploadFiles('salon-works', applicationID, salonWorks);
    const worksPayload = buildWorksPayload(salonID, workURLs, salonWorks);

    setSubmitState({ status: 'submitting', message: '正在建立沙龍 pending 申請...' });
    const { error } = await supabase.from('salon_applications').insert({
      id: applicationID,
      submitted_by: null,
      salon_id: salonID,
      name: salonName.trim(),
      location: `${salonDistrict} · ${salonLocation.trim()}`,
      distance: 0,
      rating: 5,
      tags: salonTags,
      open_hours: salonHours.trim(),
      phone: salonPhone.trim(),
      start_price: toInt(salonStartPrice),
      image_url: coverURL,
      works_payload: worksPayload,
      status: 'pending',
      admin_note: [
        '公開申請網站提交：沙龍',
        `聯絡人：${applicantName}`,
        `Email：${applicantEmail}`,
        `申請人電話：${applicantPhone}`,
        `沙龍電話：${salonPhone}`,
        `地區：${salonDistrict}`,
        `地址：${salonLocation}`,
        `特色：${salonFeatures.join('、') || '未提供'}`,
        `介紹：${salonIntro}`,
        `服務：${services.map((item) => `${item.name} HK$${item.price}`).join('；')}`,
        `作品數量：${workURLs.length}`,
      ].join('\n'),
    });

    if (error) throw error;
    setSubmitState({ status: 'success', applicationID, kind: 'salon' });
    resetSalonMediaOnly();
  }

  function addService() {
    setServices((current) => [...current, { name: '', category: '剪髮', duration: '60', price: '', description: '' }]);
  }

  function updateService(index: number, key: keyof ServiceDraft, value: string) {
    setServices((current) => current.map((item, itemIndex) => (itemIndex === index ? { ...item, [key]: value } : item)));
  }

  function removeService(index: number) {
    setServices((current) => current.filter((_, itemIndex) => itemIndex !== index));
  }

  function addCustomTag(target: 'stylist' | 'salon' | 'feature') {
    if (target === 'stylist') {
      addUniqueChip(customStylistTag, stylistTags, setStylistTags);
      setCustomStylistTag('');
    } else if (target === 'salon') {
      addUniqueChip(customSalonTag, salonTags, setSalonTags);
      setCustomSalonTag('');
    } else {
      addUniqueChip(customFeature, salonFeatures, setSalonFeatures);
      setCustomFeature('');
    }
  }

  function resetStylistMediaOnly() {
    setStylistAvatar([]);
    setStylistWorks([]);
  }

  function resetSalonMediaOnly() {
    setSalonCover([]);
    setSalonWorks([]);
  }

  return (
    <main className="apply-shell">
      <section className="hero-band">
        <div>
          <p className="eyebrow">HAIRMAP PARTNER INTAKE</p>
          <h1>髮型師 / 沙龍申請網站</h1>
          <p>
            填妥資料後會直接送到 Hairmap 管理後台，狀態為「待審批」。資料經管理員批准後，才會正式顯示在 iOS App。
          </p>
        </div>
        <div className="hero-card">
          <Sparkles size={24} />
          <strong>{readySummary.title}</strong>
          <span>{readySummary.subtitle}</span>
          <em>{readySummary.photoCount} 張作品相片</em>
        </div>
      </section>

      <form className="apply-layout" onSubmit={handleSubmit}>
        <aside className="side-panel">
          <div className="brand-lockup">
            <span>H</span>
            <strong>Hairmap</strong>
          </div>
          <div className="role-switch" role="tablist" aria-label="申請類型">
            <button type="button" className={kind === 'stylist' ? 'active' : ''} onClick={() => setKind('stylist')}>
              <Scissors size={18} />
              髮型師
            </button>
            <button type="button" className={kind === 'salon' ? 'active' : ''} onClick={() => setKind('salon')}>
              <Building2 size={18} />
              沙龍
            </button>
          </div>
          <div className="mini-steps">
            <span><Check size={15} /> 上載資料</span>
            <span><Check size={15} /> 管理員審批</span>
            <span><Check size={15} /> App 上架顯示</span>
          </div>
        </aside>

        <section className="form-panel">
          <Panel title="申請人聯絡資料" icon={<UserRound size={18} />} note="只供 Hairmap 團隊聯絡及審批使用，不會直接顯示在 App。">
            <div className="grid two">
              <Field label="聯絡人姓名" value={applicantName} onChange={setApplicantName} placeholder="例如：Kelvin Fung" required />
              <Field label="聯絡電話" value={applicantPhone} onChange={setApplicantPhone} placeholder="+852 6123 4567" required icon={<Phone size={16} />} />
              <Field label="Email" value={applicantEmail} onChange={setApplicantEmail} placeholder="name@example.com" required icon={<Mail size={16} />} className="span-2" />
            </div>
          </Panel>

          {kind === 'stylist' ? (
            <>
              <Panel title="髮型師檔案" icon={<Scissors size={18} />} note="此區會成為 iOS App 髮型師檔案的主要內容。">
                <div className="grid two">
                  <Field label="髮型師姓名" value={stylistName} onChange={setStylistName} placeholder="例如：Leo Master" required />
                  <Field label="頭銜職稱" value={stylistTitle} onChange={setStylistTitle} placeholder="例如：首席設計師 / 挑染專家" required />
                  <Field label="髮型師電話" value={stylistPhone} onChange={setStylistPhone} placeholder="+852 2345 6789" required icon={<Phone size={16} />} />
                  <SelectField label="主要地區" value={stylistDistrict} onChange={setStylistDistrict} options={DISTRICTS} />
                  <Field label="年資" value={stylistExperience} onChange={setStylistExperience} placeholder="例如：8年資歷" />
                  <Field label="語言" value={stylistLanguages} onChange={setStylistLanguages} placeholder="例如：中 / 粵 / 英" />
                  <Field label="所屬工作室 / 沙龍" value={stylistWorkplace} onChange={setStylistWorkplace} placeholder="如未有固定店可留空" className="span-2" />
                  <Textarea label="個人簡介 Bio" value={stylistBio} onChange={setStylistBio} placeholder="介紹您的專長、服務風格、常見客群與作品方向。" required className="span-2" />
                  <Field label="最低服務價 HK$" value={stylistBasePrice} onChange={setStylistBasePrice} placeholder="380" />
                </div>
                <ChipPicker title="專長 Tags" options={DEFAULT_STYLIST_TAGS} values={stylistTags} onChange={setStylistTags} />
                <CustomChipInput value={customStylistTag} onChange={setCustomStylistTag} onAdd={() => addCustomTag('stylist')} placeholder="新增專長，例如：羊毛卷" />
              </Panel>

              <Panel title="頭像與作品集" icon={<Camera size={18} />} note="頭像必填；作品相片可多選，會以固定比例送到後台。">
                <FilePicker title="髮型師頭像" files={stylistAvatar} onChange={setStylistAvatar} max={1} required />
                <FilePicker title="作品集相片" files={stylistWorks} onChange={setStylistWorks} max={12} />
              </Panel>
            </>
          ) : (
            <>
              <Panel title="沙龍檔案" icon={<Building2 size={18} />} note="此區會成為 iOS App 沙龍檔案的主要內容。">
                <div className="grid two">
                  <Field label="沙龍名稱" value={salonName} onChange={setSalonName} placeholder="例如：Maison de Beauté" required />
                  <SelectField label="主要地區" value={salonDistrict} onChange={setSalonDistrict} options={DISTRICTS} />
                  <Field label="完整地址" value={salonLocation} onChange={setSalonLocation} placeholder="例如：尖沙咀海港城 3 樓 3045 號舖" required className="span-2" />
                  <Field label="沙龍電話" value={salonPhone} onChange={setSalonPhone} placeholder="+852 2345 6789" required icon={<Phone size={16} />} />
                  <Field label="營業時間" value={salonHours} onChange={setSalonHours} placeholder="11:00 - 20:00" />
                  <Field label="最低服務價 HK$" value={salonStartPrice} onChange={setSalonStartPrice} placeholder="480" />
                  <Textarea label="沙龍介紹 Info" value={salonIntro} onChange={setSalonIntro} placeholder="介紹空間、位置、服務特色、品牌理念與設備。" required className="span-2" />
                </div>
                <ChipPicker title="沙龍風格 Tags" options={DEFAULT_SALON_TAGS} values={salonTags} onChange={setSalonTags} />
                <CustomChipInput value={customSalonTag} onChange={setCustomSalonTag} onAdd={() => addCustomTag('salon')} placeholder="新增風格，例如：日系透明感" />
                <ChipPicker title="沙龍特色" options={DEFAULT_FEATURES} values={salonFeatures} onChange={setSalonFeatures} />
                <CustomChipInput value={customFeature} onChange={setCustomFeature} onAdd={() => addCustomTag('feature')} placeholder="新增特色，例如：近地鐵出口" />
              </Panel>

              <Panel title="封面與環境作品" icon={<ImagePlus size={18} />} note="封面必填；環境 / 作品相片可多選，會以固定比例送到後台。">
                <FilePicker title="沙龍封面" files={salonCover} onChange={setSalonCover} max={1} required />
                <FilePicker title="沙龍環境 / 技術作品" files={salonWorks} onChange={setSalonWorks} max={12} />
              </Panel>
            </>
          )}

          <Panel title="服務項目" icon={<BadgeCheck size={18} />} note="至少保留一項服務。批准後會成為 App 的服務清單參考。">
            <div className="service-list">
              {services.map((service, index) => (
                <div className="service-card" key={index}>
                  <div className="service-head">
                    <strong>服務 {index + 1}</strong>
                    {services.length > 1 && (
                      <button type="button" onClick={() => removeService(index)} aria-label="刪除服務">
                        <Trash2 size={16} />
                      </button>
                    )}
                  </div>
                  <div className="grid two compact">
                    <Field label="服務名稱" value={service.name} onChange={(value) => updateService(index, 'name', value)} placeholder="例如：招牌剪髮" />
                    <Field label="類別" value={service.category} onChange={(value) => updateService(index, 'category', value)} placeholder="剪髮 / 染髮 / 護理" />
                    <Field label="需時分鐘" value={service.duration} onChange={(value) => updateService(index, 'duration', value)} placeholder="60" />
                    <Field label="價錢 HK$" value={service.price} onChange={(value) => updateService(index, 'price', value)} placeholder="380" />
                    <Field label="簡短描述" value={service.description} onChange={(value) => updateService(index, 'description', value)} placeholder="包含洗髮與造型" className="span-2" />
                  </div>
                </div>
              ))}
            </div>
            <button type="button" className="ghost-action" onClick={addService}>
              <Plus size={16} />
              新增服務項目
            </button>
          </Panel>

          {submitState.status === 'error' && <div className="alert error">{submitState.message}</div>}
          {submitState.status === 'submitting' && (
            <div className="alert loading">
              <Loader2 size={18} className="spin" />
              {submitState.message}
            </div>
          )}
          {submitState.status === 'success' && (
            <div className="alert success">
              <Check size={20} />
              <div>
                <strong>已提交，等待審批</strong>
                <span>申請編號：{submitState.applicationID}</span>
              </div>
            </div>
          )}

          <button className="submit-button" type="submit" disabled={submitState.status === 'submitting'}>
            {submitState.status === 'submitting' ? <Loader2 size={20} className="spin" /> : <Send size={20} />}
            提交申請到 Hairmap 後台
            <ArrowRight size={20} />
          </button>
        </section>
      </form>
    </main>
  );
}

function Panel({ title, icon, note, children }: { title: string; icon: ReactNode; note?: string; children: ReactNode }) {
  return (
    <section className="panel">
      <div className="panel-heading">
        <h2>{icon}{title}</h2>
        {note && <p>{note}</p>}
      </div>
      {children}
    </section>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  required,
  icon,
  className = '',
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  required?: boolean;
  icon?: ReactNode;
  className?: string;
}) {
  return (
    <label className={`field ${className}`}>
      <span>{label}{required && <em>*</em>}</span>
      <div className="input-shell">
        {icon}
        <input value={value} onChange={(event) => onChange(event.target.value)} placeholder={placeholder} required={required} />
      </div>
    </label>
  );
}

function SelectField({ label, value, onChange, options }: { label: string; value: string; onChange: (value: string) => void; options: string[] }) {
  return (
    <label className="field">
      <span>{label}</span>
      <div className="input-shell">
        <select value={value} onChange={(event) => onChange(event.target.value)}>
          {options.map((option) => <option key={option} value={option}>{option}</option>)}
        </select>
      </div>
    </label>
  );
}

function Textarea({
  label,
  value,
  onChange,
  placeholder,
  required,
  className = '',
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  required?: boolean;
  className?: string;
}) {
  return (
    <label className={`field ${className}`}>
      <span>{label}{required && <em>*</em>}</span>
      <textarea value={value} onChange={(event) => onChange(event.target.value)} placeholder={placeholder} required={required} />
    </label>
  );
}

function ChipPicker({ title, options, values, onChange }: { title: string; options: string[]; values: string[]; onChange: (values: string[]) => void }) {
  return (
    <div className="chip-block">
      <strong>{title}</strong>
      <div className="chips">
        {options.map((option) => {
          const selected = values.includes(option);
          return (
            <button
              type="button"
              className={selected ? 'selected' : ''}
              key={option}
              onClick={() => onChange(selected ? values.filter((item) => item !== option) : [...values, option])}
            >
              {selected && <Check size={13} />}
              {option}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function CustomChipInput({ value, onChange, onAdd, placeholder }: { value: string; onChange: (value: string) => void; onAdd: () => void; placeholder: string }) {
  return (
    <div className="custom-chip">
      <input value={value} onChange={(event) => onChange(event.target.value)} placeholder={placeholder} />
      <button type="button" onClick={onAdd}>加入</button>
    </div>
  );
}

function FilePicker({
  title,
  files,
  onChange,
  max,
  required,
}: {
  title: string;
  files: File[];
  onChange: (files: File[]) => void;
  max: number;
  required?: boolean;
}) {
  function handleFiles(event: ChangeEvent<HTMLInputElement>) {
    const selected = Array.from(event.target.files ?? []).filter((file) => file.type.startsWith('image/'));
    onChange([...files, ...selected].slice(0, max));
    event.target.value = '';
  }

  return (
    <div className="file-picker">
      <div className="file-head">
        <strong>{title}{required && <em>*</em>}</strong>
        <span>{files.length} / {max}</span>
      </div>
      <label className="dropzone">
        <UploadCloud size={26} />
        <span>點擊上載相片，可一次多選</span>
        <input type="file" accept="image/*" multiple={max > 1} onChange={handleFiles} />
      </label>
      {files.length > 0 && (
        <div className="preview-grid">
          {files.map((file, index) => (
            <figure key={`${file.name}-${file.lastModified}-${index}`}>
              <img src={URL.createObjectURL(file)} alt={file.name} />
              <figcaption>{file.name}</figcaption>
              <button type="button" onClick={() => onChange(files.filter((_, fileIndex) => fileIndex !== index))} aria-label="移除相片">
                <Trash2 size={14} />
              </button>
            </figure>
          ))}
        </div>
      )}
    </div>
  );
}

async function uploadFiles(kind: string, applicationID: string, files: File[]) {
  const urls: string[] = [];
  for (const file of files) {
    const path = `public-applications/${kind}/${applicationID}/${randomID()}-${safeFileName(file.name)}`;
    const { error } = await supabase.storage.from('hairmap-media').upload(path, file, {
      contentType: file.type || 'image/jpeg',
      upsert: false,
    });
    if (error) throw error;
    const { data } = supabase.storage.from('hairmap-media').getPublicUrl(path);
    urls.push(data.publicUrl);
  }
  return urls;
}

function buildServicePayload(stylistID: string, services: ServiceDraft[]) {
  return services
    .filter((item) => item.name.trim())
    .map((item, index) => ({
      id: `${stylistID}-service-${index + 1}`,
      stylist_id: stylistID,
      name: item.name.trim(),
      category: item.category.trim() || '剪髮',
      duration: toInt(item.duration, 60),
      description: item.description.trim(),
      price: toInt(item.price),
    }));
}

function buildWorksPayload(ownerID: string, urls: string[], files: File[]) {
  return urls.map((url, index) => ({
    id: `${ownerID}-work-${index + 1}`,
    stylist_id: ownerID,
    title: fileTitle(files[index]?.name, `作品 ${index + 1}`),
    image_url: url,
    is_active: true,
    display_order: (index + 1) * 10,
  }));
}

function validateCommon(name: string, email: string, phone: string) {
  if (!name.trim()) throw new Error('請填寫聯絡人姓名。');
  if (!email.trim() || !email.includes('@')) throw new Error('請填寫有效 Email。');
  if (!phone.trim()) throw new Error('請填寫聯絡電話。');
}

function addUniqueChip(value: string, values: string[], setter: (values: string[]) => void) {
  const next = value.trim();
  if (!next) return;
  if (!values.includes(next)) setter([...values, next]);
}

function toInt(value: string, fallback = 0) {
  const parsed = Number.parseInt(value.replace(/[^\d]/g, ''), 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function fileTitle(name: string | undefined, fallback: string) {
  if (!name) return fallback;
  return name.replace(/\.[^.]+$/, '').replace(/[-_]+/g, ' ').trim() || fallback;
}

function makePublicID(prefix: string, label: string) {
  const slug = label
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 34);
  return `${prefix}-${slug || 'hairmap'}-${randomID().slice(0, 8)}`;
}

function randomID() {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) return crypto.randomUUID();
  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function safeFileName(name: string) {
  const cleaned = name
    .toLowerCase()
    .replace(/[^a-z0-9.]+/g, '-')
    .replace(/^-+|-+$/g, '');
  return cleaned || 'hairmap-upload.jpg';
}

export default App;
