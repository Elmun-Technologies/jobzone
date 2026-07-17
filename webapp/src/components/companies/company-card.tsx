"use client";

import { BadgeCheck, Briefcase, MapPin } from "lucide-react";
import Image from "next/image";
import { useTranslations } from "next-intl";

import { Link } from "@/i18n/navigation";
import type { CompanyWithJobs } from "@/lib/data/types";

export function CompanyCard({ company }: { company: CompanyWithJobs }) {
  const t = useTranslations("company");
  const meta = [company.industry, company.headquarters]
    .filter(Boolean)
    .join(" · ");

  return (
    <Link
      href={`/companies/${company.id}`}
      className="border-border bg-card hover:border-primary/40 flex h-full flex-col gap-3 rounded-xl border p-4 transition-all hover:shadow-sm"
    >
      <div className="flex items-center gap-3">
        {company.logoUrl ? (
          <Image
            src={company.logoUrl}
            alt={company.name}
            width={48}
            height={48}
            loading="lazy"
            sizes="48px"
            className="size-12 shrink-0 rounded-lg object-cover"
          />
        ) : (
          <div className="bg-primary text-primary-foreground flex size-12 shrink-0 items-center justify-center rounded-lg text-lg font-bold">
            {company.name.charAt(0).toUpperCase()}
          </div>
        )}
        <div className="min-w-0">
          <h3 className="text-foreground flex items-center gap-1 font-semibold">
            <span className="truncate">{company.name}</span>
            {company.isVerified ? (
              <BadgeCheck className="text-primary size-4 shrink-0" />
            ) : null}
          </h3>
          {meta ? (
            <p className="text-muted-foreground mt-0.5 flex items-center gap-1 text-sm">
              <MapPin className="size-3.5 shrink-0" />
              <span className="truncate">{meta}</span>
            </p>
          ) : null}
        </div>
      </div>

      <p className="text-muted-foreground mt-auto flex items-center gap-1.5 text-sm">
        <Briefcase className="size-3.5" />
        {t("openJobsCount", { count: company.openJobs })}
      </p>
    </Link>
  );
}
