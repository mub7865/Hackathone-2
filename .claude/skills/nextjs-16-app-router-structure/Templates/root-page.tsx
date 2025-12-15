/**
 * Standard root page for `/` in a Next.js 16 App Router app.
 *
 * RULES:
 * - Keep it simple and stateless by default.
 * - Use this as a starting point; replace content based on the project spec.
 */

export default function HomePage() {
  return (
    <main className="min-h-screen flex items-center justify-center">
      <div className="text-center space-y-2">
        <h1 className="text-2xl font-semibold">
          Next.js App Router Starter
        </h1>
        <p className="text-sm text-gray-500">
          Replace this content according to the project specification.
        </p>
      </div>
    </main>
  );
}
