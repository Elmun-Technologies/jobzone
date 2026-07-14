import Script from "next/script";

/**
 * Yandex.Metrica loader — Yandex is ~40% of UZ search traffic and the
 * ecosystem seekers already use; installing it alongside GA4 covers the
 * two engines that actually drive volume here.
 *
 * The snippet Metrica prints on install is a self-contained IIFE. We
 * render it via next/script (afterInteractive) so the loader itself
 * defers past LCP, then call `ym(id, 'init', ...)` with webvisor +
 * clickmap on — those are the two features Metrica is uniquely good
 * at (session replay + heatmaps) and the reason to install it on top
 * of GA4 rather than duplicating page views.
 *
 * Renders nothing when `counterId` is empty — dev/preview stays silent.
 */
export function YandexMetrica({ counterId }: { counterId: string }) {
  if (!counterId) return null;
  return (
    <>
      <Script id="yandex-metrica" strategy="afterInteractive">
        {`(function(m,e,t,r,i,k,a){m[i]=m[i]||function(){(m[i].a=m[i].a||[]).push(arguments)};m[i].l=1*new Date();for(var j=0;j<document.scripts.length;j++){if(document.scripts[j].src===r){return;}}k=e.createElement(t),a=e.getElementsByTagName(t)[0],k.async=1,k.src=r,a.parentNode.insertBefore(k,a)})(window,document,'script','https://mc.yandex.ru/metrika/tag.js?id=${counterId}','ym');
ym(${counterId},'init',{ssr:true,webvisor:true,clickmap:true,ecommerce:"dataLayer",accurateTrackBounce:true,trackLinks:true});`}
      </Script>
      {/* Fallback pixel for JS-off / bot traffic. left:-9999px keeps it
          out of layout while still being fetched. */}
      <noscript>
        <div>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={`https://mc.yandex.ru/watch/${counterId}`}
            style={{ position: "absolute", left: "-9999px" }}
            alt=""
          />
        </div>
      </noscript>
    </>
  );
}
