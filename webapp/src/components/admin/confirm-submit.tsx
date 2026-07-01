"use client";

import { useEffect, useState } from "react";

import { Button, type ButtonProps } from "@/components/ui/button";
import { adminStrings } from "@/lib/admin/strings";

/**
 * Two-step submit for destructive/irreversible admin actions (block, complete
 * a top-up, broadcast): first click arms it ("Ishonchingiz komilmi?"), second
 * click within 4s actually submits the surrounding form.
 */
export function ConfirmSubmit({
  children,
  confirmLabel = adminStrings.confirmAsk,
  ...props
}: ButtonProps & { confirmLabel?: string }) {
  const [armed, setArmed] = useState(false);

  useEffect(() => {
    if (!armed) return;
    const t = setTimeout(() => setArmed(false), 4000);
    return () => clearTimeout(t);
  }, [armed]);

  if (!armed) {
    return (
      <Button
        {...props}
        type="button"
        onClick={(e) => {
          e.preventDefault();
          setArmed(true);
        }}
      >
        {children}
      </Button>
    );
  }
  return (
    <Button {...props} type="submit" variant="outline">
      {confirmLabel}
    </Button>
  );
}
