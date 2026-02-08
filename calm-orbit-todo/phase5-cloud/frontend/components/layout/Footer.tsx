'use client';

/**
 * Footer – Authenticated footer with sticky behavior
 * Feature: 006-ui-theme-motion (FR-050, FR-051, FR-052, FR-053, FR-054, SC-016)
 *
 * - "Built with Spec-Driven Development" on left
 * - "Docs · GitHub · Contact" links on right (placeholder hrefs)
 * - Subtle top border
 * - STICKY FOOTER pattern: at viewport bottom when content short, after content when tall
 * - Must not overlap main content
 */
export function Footer() {
  return (
    <footer
      className={`
        w-full
        py-4 px-6
        border-t border-border-subtle
        bg-background-base/80 backdrop-blur-sm
        text-caption text-text-muted
      `.replace(/\s+/g, ' ').trim()}
    >
      <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-2">
        {/* Left: Branding */}
        <span>Built with Spec-Driven Development</span>

        {/* Right: Links */}
        <div className="flex items-center gap-3">
          <a
            href="#"
            className="hover:text-text-secondary transition-colors duration-fast"
          >
            Docs
          </a>
          <span className="text-border-subtle">·</span>
          <a
            href="#"
            className="hover:text-text-secondary transition-colors duration-fast"
          >
            GitHub
          </a>
          <span className="text-border-subtle">·</span>
          <a
            href="#"
            className="hover:text-text-secondary transition-colors duration-fast"
          >
            Contact
          </a>
        </div>
      </div>
    </footer>
  );
}
