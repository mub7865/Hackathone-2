"use client";

import { ReactNode } from "react";
import { HoverLift } from "@/components/motion/patterns";

interface BaseCardProps {
  children: ReactNode;
  as?: "div" | "section" | "article";
  highlight?: boolean;
  className?: string;
}

export function BaseCard({
  children,
  as: Component = "div",
  highlight = false,
  className = "",
}: BaseCardProps) {
  const base =
    "rounded-xl border border-slate-200 bg-white/80 backdrop-blur-sm shadow-sm px-5 py-4";
  const highlightClasses = highlight
    ? "border-blue-500 shadow-md shadow-blue-100"
    : "";
  const classes = [base, highlightClasses, className]
    .filter(Boolean)
    .join(" ");

  return (
    <HoverLift>
      <Component className={classes}>{children}</Component>
    </HoverLift>
  );
}
