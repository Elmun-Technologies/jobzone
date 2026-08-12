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

const DEFAULT_VALID_THROUGH = new Date(
  Date.now() + 30 * 24 * 60 * 60 * 1000,
).toISOString();

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
    validThrough: validThrough || DEFAULT_VALID_THROUGH,
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
