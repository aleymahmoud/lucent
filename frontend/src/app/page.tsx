import { redirect } from 'next/navigation';

export default function Home() {
  // Redirect to dashboard (basePath /lucent is automatically prepended)
  redirect('/dashboard');
}
