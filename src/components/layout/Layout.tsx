import { type ReactNode } from "react";
import { Header } from "./Header";
import { Footer } from "./Footer";
import { AnnouncementBanner } from "./AnnouncementBanner";
import { WhatsAppButton } from "./WhatsAppButton";
import { useStoreSettings } from "@/lib/hooks";

export function Layout({ children }: { children: ReactNode }) {
  const { data: settings } = useStoreSettings();

  return (
    <>
      {settings?.tagline && <AnnouncementBanner text={settings.tagline} />}
      <Header storeName={settings?.store_name ?? "JACOB DE JESUS"} />
      <main>{children}</main>
      <Footer settings={settings} />
      {settings?.phone && <WhatsAppButton phone={settings.phone} />}
    </>
  );
}
