import React from 'react';

interface JobJsonLdProps {
  title: string;
  description: string;
  datePosted: string;
  validThrough?: string;
  employmentType: string;
  hiringOrganizationName: string;
  hiringOrganizationLogo?: string;
  city: string;
  salaryMin?: number;
  salaryMax?: number;
}

export function JobJsonLd({
  title,
  description,
  datePosted,
  validThrough,
  employmentType,
  hiringOrganizationName,
  hiringOrganizationLogo,
  city,
  salaryMin,
  salaryMax,
}: JobJsonLdProps) {
  const jsonLd = {
    '@context': 'https://schema.org/',
    '@type': 'JobPosting',
    title,
    description,
    datePosted,
    // Derive from the posted date (pure) — Date.now() during render fails
    // react-hooks/purity and would also drift the JSON-LD on every render.
    validThrough:
      validThrough ||
      new Date(
        new Date(datePosted).getTime() + 30 * 24 * 60 * 60 * 1000,
      ).toISOString(),
    employmentType: employmentType.toUpperCase().replace('-', '_'),
    hiringOrganization: {
      '@type': 'Organization',
      name: hiringOrganizationName,
      logo: hiringOrganizationLogo,
    },
    jobLocation: {
      '@type': 'Place',
      address: {
        '@type': 'PostalAddress',
        addressLocality: city,
        addressCountry: 'UZ',
      },
    },
    ...(salaryMin && salaryMax
      ? {
          baseSalary: {
            '@type': 'MonetaryAmount',
            currency: 'UZS',
            value: {
              '@type': 'QuantitativeValue',
              minValue: salaryMin,
              maxValue: salaryMax,
              unitText: 'MONTH',
            },
          },
        }
      : {}),
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  );
}
