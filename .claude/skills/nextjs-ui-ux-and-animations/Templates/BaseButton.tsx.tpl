"use client";

import { ButtonHTMLAttributes, ReactNode } from "react";
import { HoverLift } from "@/components/motion/patterns";

type ButtonVariant = "primary" | "secondary" | "ghost";
type ButtonSize = "sm" | "md" | "lg";

interface BaseButtonProps
  extends ButtonHTMLAttributes<HTMLButtonElement> {
  children: ReactNode;
  variant?: ButtonVariant;
  size?: ButtonSize;
  fullWidth?: boolean;
}

const baseClasses =
  "inline-flex items-center justify-center rounded-md font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:opacity-60 disabled:cursor-not-allowed transition-colors";

const variantClasses: Record<ButtonVariant, string> = {
  primary:
    "bg-blue-600 text-white hover:bg-blue-500 focus-visible:ring-blue-500",
  secondary:
    "bg-slate-800 text-white hover:bg-slate-700 focus-visible:ring-slate-700",
  ghost:
    "bg-transparent text-slate-900 hover:bg-slate-100 focus-visible:ring-slate-400",
};

const sizeClasses: Record<ButtonSize, string> = {
  sm: "text-sm px-3 py-1.5 gap-1",
  md: "text-sm px-4 py-2 gap-2",
  lg: "text-base px-5 py-2.5 gap-2",
};

export function BaseButton({
  children,
  variant = "primary",
  size = "md",
  fullWidth,
  className = "",
  ...props
}: BaseButtonProps) {
  const widthClass = fullWidth ? "w-full" : "";
  const classes = [
    baseClasses,
    variantClasses[variant],
    sizeClasses[size],
    widthClass,
    className,
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <HoverLift className={fullWidth ? "w-full" : undefined}>
      <button type="button" className={classes} {...props}>
        {children}
      </button>
    </HoverLift>
  );
}
