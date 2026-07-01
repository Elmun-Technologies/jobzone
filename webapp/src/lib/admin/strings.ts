/**
 * Admin panel copy — Uzbek only, by design. The panel is an internal tool for
 * the technical team, so it deliberately lives outside next-intl (no ru/en
 * catalogs, no parity-test surface). Repeated labels live here; one-off page
 * copy may stay inline in the page components.
 */
export const adminStrings = {
  brand: "Yolla Admin",
  panelTitle: "Boshqaruv paneli",
  demoMode: "Demo rejim — Supabase sozlanmagan, ma'lumotlar namunaviy",
  loadError: "Ma'lumotlarni yuklab bo'lmadi",
  loadErrorHint: "Keyinroq qayta urinib ko'ring yoki konsol loglarini tekshiring.",
  readKeyMissing: "O'qish kaliti sozlanmagan",
  readKeyMissingHint:
    "SUPABASE_SERVICE_ROLE_KEY o'rnatilmagan — ro'yxatlar shu kalitsiz o'qilmaydi.",
  comingSoon: "Tez kunda",
  save: "Saqlash",
  cancel: "Bekor qilish",
  confirm: "Tasdiqlash",
  confirmAsk: "Ishonchingiz komilmi?",
  search: "Qidirish",
  empty: "Hech narsa topilmadi",
  prev: "Oldingi",
  next: "Keyingi",
  nav: {
    groups: {
      overview: "Boshqaruv",
      moderation: "Moderatsiya",
      content: "Kontent",
      finance: "Moliya",
      system: "Tizim",
    },
    dashboard: "Dashboard",
    users: "Foydalanuvchilar",
    companies: "Kompaniyalar",
    jobs: "E'lonlar",
    reviews: "Sharhlar",
    categories: "Kategoriyalar",
    products: "Mahsulotlar",
    blog: "Blog",
    wallet: "Hamyon",
    orders: "Buyurtmalar",
    broadcast: "Xabarnoma",
    settings: "Sozlamalar",
    audit: "Jurnal",
  },
} as const;
