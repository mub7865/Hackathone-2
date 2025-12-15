import { redirect } from 'next/navigation';

export default function HomePage() {
  // Redirect home to tasks page
  redirect('/tasks');
}
