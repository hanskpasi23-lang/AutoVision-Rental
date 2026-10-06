'use client';

import { useAuth } from "@/context/AuthContext";
import { useEffect, useState } from "react";
import Link from "next/link";
import { Car, CheckCircle, TrendingUp, AlertCircle } from "lucide-react";

interface UserStats {
    active_rentals: number;
    completed_rentals: number;
    credit_score: number;
    recent_rentals?: {
        id: number;
        vehicle: string;
        vehicle_image: string | null;
        start_date: string;
        end_date: string;
        total_price: number;
        status: string;
    }[];
}

export default function DashboardPage() {
    const { user, token } = useAuth();
    const [stats, setStats] = useState<UserStats | null>(null);
    const [loading, setLoading] = useState(true);

    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    useEffect(() => {
        const fetchStats = async () => {
            if (!token) return;
            try {
                const response = await fetch(`${API_URL}/dashboard/user-stats`, {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });
                if (response.ok) {
                    const data = await response.json();
                    setStats(data);
                }
            } catch (error) {
                console.error("Error fetching dashboard stats:", error);
            } finally {
                setLoading(false);
            }
        };

        fetchStats();
    }, [token, API_URL]);

    return (
        <div className="space-y-6">
            <div className="bg-white dark:bg-gray-800 shadow rounded-lg p-6">
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                    Welcome back, {user?.full_name || user?.email || 'User'}!
                </h1>
                <p className="mt-2 text-gray-600 dark:text-gray-400">
                    Here is an overview of your rental activity and standing.
                </p>
            </div>

            {loading ? (
                <div className="flex justify-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
                </div>
            ) : (
                <div className="space-y-8">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                        {}
                        <div className="bg-white dark:bg-gray-800 shadow rounded-xl p-6 border-l-4 border-blue-500">
                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-sm font-medium text-gray-500 dark:text-gray-400">Active Rentals</p>
                                    <p className="text-3xl font-bold text-gray-900 dark:text-white mt-2">
                                        {stats?.active_rentals || 0}
                                    </p>
                                </div>
                                <div className="p-3 bg-blue-100 dark:bg-blue-900/30 rounded-full">
                                    <Car className="w-6 h-6 text-blue-600 dark:text-blue-400" />
                                </div>
                            </div>
                        </div>

                        {}
                        <div className="bg-white dark:bg-gray-800 shadow rounded-xl p-6 border-l-4 border-green-500">
                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-sm font-medium text-gray-500 dark:text-gray-400">Completed Rentals</p>
                                    <p className="text-3xl font-bold text-gray-900 dark:text-white mt-2">
                                        {stats?.completed_rentals || 0}
                                    </p>
                                </div>
                                <div className="p-3 bg-green-100 dark:bg-green-900/30 rounded-full">
                                    <CheckCircle className="w-6 h-6 text-green-600 dark:text-green-400" />
                                </div>
                            </div>
                        </div>

                        {}
                        <div className={`bg-white dark:bg-gray-800 shadow rounded-xl p-6 border-l-4 ${(stats?.credit_score || 0) >= 80 ? 'border-purple-500' :
                            (stats?.credit_score || 0) >= 50 ? 'border-yellow-500' : 'border-red-500'
                            }`}>
                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-sm font-medium text-gray-500 dark:text-gray-400">Credit Score</p>
                                    <p className="text-3xl font-bold text-gray-900 dark:text-white mt-2">
                                        {stats?.credit_score?.toFixed(1) || 'N/A'}
                                    </p>
                                </div>
                                <div className={`p-3 rounded-full ${(stats?.credit_score || 0) >= 80 ? 'bg-purple-100 dark:bg-purple-900/30 text-purple-600' :
                                    (stats?.credit_score || 0) >= 50 ? 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-600' : 'bg-red-100 dark:bg-red-900/30 text-red-600'
                                    }`}>
                                    <TrendingUp className="w-6 h-6" />
                                </div>
                            </div>
                        </div>
                    </div>

                    <div>
                        <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">Recent Rentals</h2>
                        {stats?.recent_rentals && stats.recent_rentals.length > 0 ? (
                            <div className="bg-white dark:bg-gray-800 shadow rounded-xl overflow-hidden">
                                <ul className="divide-y divide-gray-200 dark:divide-gray-700">
                                    {stats.recent_rentals.map((rental) => (
                                        <Link href={`/dashboard/bookings/${rental.id}`} key={rental.id} className="block hover:bg-gray-50 dark:hover:bg-gray-700 transition">
                                            <li className="p-4 flex items-center gap-4">
                                                <div className="h-12 w-16 bg-gray-100 rounded overflow-hidden flex-shrink-0">
                                                    {rental.vehicle_image ? (
                                                        <img src={rental.vehicle_image.startsWith('http') ? rental.vehicle_image : `${API_URL}${rental.vehicle_image}`} alt={rental.vehicle} className="h-full w-full object-cover" />
                                                    ) : (
                                                        <div className="h-full w-full flex items-center justify-center text-gray-400">
                                                            <Car className="w-6 h-6" />
                                                        </div>
                                                    )}
                                                </div>
                                                <div className="flex-1 min-w-0">
                                                    <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                                                        {rental.vehicle}
                                                    </p>
                                                    <p className="text-xs text-gray-500 dark:text-gray-400">
                                                        {new Date(rental.start_date).toLocaleDateString()} - {new Date(rental.end_date).toLocaleDateString()}
                                                    </p>
                                                </div>
                                                <div className="text-right">
                                                    <p className="text-sm font-semibold text-gray-900 dark:text-white">
                                                        ${rental.total_price.toFixed(2)}
                                                    </p>
                                                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize
                                                ${rental.status === 'completed' ? 'bg-green-100 text-green-800' :
                                                            rental.status === 'active' ? 'bg-blue-100 text-blue-800' :
                                                                rental.status === 'cancelled' ? 'bg-red-100 text-red-800' : 'bg-gray-100 text-gray-800'}`}>
                                                        {rental.status}
                                                    </span>
                                                </div>
                                            </li>
                                        </Link>
                                    ))}
                                </ul>
                            </div>
                        ) : (
                            <div className="bg-white dark:bg-gray-800 shadow rounded-xl p-8 text-center text-gray-500">
                                <p>No recent rentals.</p>
                                <Link href="/dashboard/browse" className="text-blue-600 hover:underline mt-2 inline-block">
                                    Browse Vehicles
                                </Link>
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
}
