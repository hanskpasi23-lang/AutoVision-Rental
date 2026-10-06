"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { LayoutDashboard, Car, BookCheck, Users, ClipboardList, Settings, LogOut, AlertTriangle } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/context/AuthContext";

const routes = [
    {
        label: "Dashboard",
        icon: LayoutDashboard,
        href: "/admin",
        color: "text-sky-500",
    },
    {
        label: "Vehicles",
        icon: Car,
        href: "/admin/vehicles",
        color: "text-violet-500",
    },
    {
        label: "Bookings",
        icon: BookCheck,
        href: "/admin/bookings",
        color: "text-pink-700",
    },
    {
        label: "Users",
        icon: Users,
        href: "/admin/users",
        color: "text-orange-700",
    },
    {
        label: "Inspections",
        icon: ClipboardList,
        href: "/admin/inspections",
        color: "text-emerald-500",
    },
    {
        label: "Incidents",
        icon: AlertTriangle,
        href: "/admin/incidents",
        color: "text-red-500",
    },
    {
        label: "Settings",
        icon: Settings,
        href: "/admin/settings",
    },
];

export const Sidebar = () => {
    const pathname = usePathname();
    const router = useRouter();
    const { logout } = useAuth();

    const handleLogout = () => {
        logout();
        router.push('/login');
    };

    return (
        <div className="space-y-4 py-4 flex flex-col h-full bg-[#111827] text-white">
            <div className="px-3 py-2 flex-1">
                <Link href="/admin" className="flex items-center mb-14 pl-2">
                    <div className="min-w-[2.5rem] h-10 w-10 bg-blue-600 rounded-lg flex items-center justify-center text-white font-bold text-xl mr-3 shrink-0">
                        AV
                    </div>
                    <h1 className="text-xl font-bold opacity-0 group-hover:opacity-100 transition-opacity duration-300 whitespace-nowrap overflow-hidden">
                        AutoVision <span className="text-blue-500">Admin</span>
                    </h1>
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

