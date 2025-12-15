"use client";

import { ReactNode } from "react";
import { FadeInSection } from "@/components/motion/patterns";

interface SectionShellProps {
  children: ReactNode;
  id?: string;
  compact?: boolean;
  className?: string;
  bleed?: boolean;
}

export function SectionShell({
  children,
  id,
  compact = false,
  className = "",
  bleed = false,
}: SectionShellProps) {
  const paddingY = compact ? "py-10 md:py-12" : "py-14 md:py-20";
  const base = `${paddingY} ${bleed ? "" : "px-4"} ${className}`;

  return (
    <FadeInSection id={id} className={base}>
      <div
        className={
          bleed
            ? "mx-auto max-w-5xl"
            : "mx-auto max-w-5xl"
        }
      >
        {children}
      </div>
    </FadeInSection>
  );
}
