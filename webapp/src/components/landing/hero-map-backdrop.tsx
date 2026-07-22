// Purely decorative — a map-grid + floating salary-pill backdrop for the
// hero, echoing the brand's map-first identity (the real interactive map
// sits lower on the page, id="map"). Static markup only (no hooks), so it
// stays a server component and costs nothing beyond the CSS animation.
const PINS: Array<{
  amount: string;
  className: string;
  delay: string;
}> = [
  { amount: "4 200 000", className: "top-[14%] left-[8%]", delay: "0s" },
  { amount: "3 000 000", className: "top-[62%] left-[14%]", delay: "0.6s" },
  { amount: "6 500 000", className: "top-[20%] right-[10%]", delay: "1.1s" },
  { amount: "5 100 000", className: "top-[68%] right-[16%]", delay: "1.7s" },
  { amount: "3 800 000", className: "top-[40%] left-[3%]", delay: "2.2s" },
];

export function HeroMapBackdrop() {
  return (
    <div aria-hidden className="pointer-events-none absolute inset-0 z-0">
      {/* Map-grid dots */}
      <div
        className="absolute inset-0 opacity-[0.35]"
        style={{
          backgroundImage:
            "radial-gradient(circle, rgba(244,246,248,0.35) 1px, transparent 1px)",
          backgroundSize: "24px 24px",
        }}
      />
      {/* Volt + blue glows for depth, matching the real map's pin/you-are-here colors */}
      <div className="bg-primary/25 absolute -top-24 -right-16 size-72 rounded-full blur-3xl" />
      <div className="absolute -bottom-24 -left-10 size-72 rounded-full bg-[#2F6BFF]/20 blur-3xl" />

      {/* "You are here" — same visual language as the real landing map */}
      <span className="absolute top-1/2 left-1/2 hidden size-3.5 -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#2F6BFF] shadow-[0_0_0_5px_rgba(47,107,255,.28)] ring-[3px] ring-white/90 sm:block" />

      {/* Floating salary pins — same pill shape as the real map markers */}
      {PINS.map((pin) => (
        <span
          key={pin.amount}
          className={`animate-float absolute hidden rounded-full bg-[#C7FB00] px-3 py-1 font-mono text-xs font-bold whitespace-nowrap text-[#0A0A0A] shadow-lg sm:block ${pin.className}`}
          style={{ animationDelay: pin.delay }}
        >
          {pin.amount}
        </span>
      ))}
    </div>
  );
}
