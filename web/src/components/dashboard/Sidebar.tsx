"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { LayoutDashboard, Car, CalendarCheck, Heart, User, LogOut } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/context/AuthContext";

const routes = [
    {
        label: "Dashboard",
        icon: LayoutDashboard,
        href: "/dashboard",
        color: "text-sky-500",
    },
    {
        label: "My Bookings",
        icon: CalendarCheck,
        href: "/dashboard/bookings",
        color: "text-violet-500",
    },
    {
        label: "Browse Vehicles",
        icon: Car,
        href: "/dashboard/browse",
        color: "text-pink-700",
    },
    {
        label: "Wishlist",
        icon: Heart,
        href: "/dashboard/wishlist",
        color: "text-red-500",
    },
    {
        label: "Profile",
        icon: User,
        href: "/dashboard/profile",
        color: "text-emerald-500",
    },
];

export const Sidebar = () => {
    const pathname = usePathname();
    const router = useRouter();
    const { user, logout } = useAuth();

    const handleLogout = () => {
        logout();
        router.push('/');
    };

    return (
        <div className="space-y-4 py-4 flex flex-col h-full bg-[#111827] text-white">
            <div className="px-3 py-2 flex-1">
                <Link href="/dashboard" className="flex items-center mb-10 pl-2">
                    <div className="min-w-[2.5rem] h-10 w-10 bg-blue-600 rounded-lg flex items-center justify-center text-white font-bold text-xl mr-3 shrink-0">
                        AV
                    </div>
                    <div className="opacity-0 group-hover:opacity-100 transition-opacity duration-300 whitespace-nowrap overflow-hidden">
                        <h1 className="text-lg font-bold">
                            AutoVision
                        </h1>
                        <p className="text-xs text-gray-400">
                            {user?.full_name || 'User Portal'}
                        </p>
                    </div>
                </Link>
                <div className="space-y-1">
                    {routes.map((route) => (
                        <Link
                            key={route.href}
                            href={route.href}
                            className={cn(
                                "text-sm flex p-3 w-full justify-start font-medium cursor-pointer hover:text-white hover:bg-white/10 rounded-lg transition whitespace-nowrap",
                                pathname === route.href ? "text-white bg-white/10" : "text-zinc-400"
                            )}
                        >
                            <div className="flex items-center flex-1">
                                <route.icon className={cn("h-5 w-5 min-w-[1.25rem] mr-4", route.color)} />
                                <span className="opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                                    {route.label}
                                </span>
                            </div>
                        </Link>
                    ))}
                </div>
            </div>
            <div className="px-3 py-2">
                <button
                    onClick={handleLogout}
                    className="text-sm flex p-3 w-full justify-start font-medium cursor-pointer hover:text-white hover:bg-white/10 rounded-lg transition text-zinc-400 whitespace-nowrap"
                >
                    <div className="flex items-center flex-1">
                        <LogOut className="h-5 w-5 min-w-[1.25rem] mr-4 text-red-500" />
                        <span className="opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                            Logout
                        </span>
                    </div>
                </button>
            </div>
        </div>
    );
}
