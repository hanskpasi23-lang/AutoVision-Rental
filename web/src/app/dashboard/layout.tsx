'use client';

import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import Link from 'next/link';
import { Sidebar } from '@/components/dashboard/Sidebar';

export default function UserLayout({ children }: { children: React.ReactNode }) {
    const { user, isLoading, isAuthenticated, logout } = useAuth();
    const router = useRouter();

    useEffect(() => {
        if (!isLoading && !isAuthenticated) {
            router.push('/login');
        }
    }, [isLoading, isAuthenticated, router]);

    if (isLoading) {
        return (
            <div className="min-h-screen flex items-center justify-center">
                <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
            </div>
        );
    }

    if (!isAuthenticated) {
        return null;
    }

    return (
        <div className="h-full relative min-h-screen bg-gray-50">
            <div className="hidden h-full md:flex md:w-20 md:hover:w-72 md:flex-col md:fixed md:inset-y-0 z-[80] bg-[#111827] transition-all duration-300 ease-in-out group overflow-hidden">
                <Sidebar />
            </div>
            <main className="md:pl-20 transition-all duration-300 ease-in-out min-h-screen">
                <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
                    {}
                    <div className="md:hidden flex items-center justify-between mb-6">
                        <Link href="/dashboard" className="text-xl font-bold text-blue-600">
                            AutoVision Rent
                        </Link>
                        <button onClick={() => router.push('/dashboard/profile')} className="p-2">
                            <span className="sr-only">Profile</span>
                            <div className="h-8 w-8 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold">
                                {user?.full_name?.[0] || 'U'}
                            </div>
                        </button>
                    </div>
                    {children}
                </div>
            </main>
        </div>
    );
}
