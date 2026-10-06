'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Users, Car, Calendar, DollarSign, AlertCircle, CheckCircle } from 'lucide-react';

interface DashboardStats {
    total_users: number;
    active_rentals: number;
    available_vehicles: number;
    total_vehicles: number;
    monthly_revenue: number;
    pending_bookings: number;
    pending_inspections: number;
}

interface RecentBooking {
    id: number;
    user_name: string;
    vehicle: string;
    status: string;
    total_price: number;
    start_date: string;
    end_date: string;
}

const AdminDashboard = () => {
    const { token } = useAuth();
    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [recentBookings, setRecentBookings] = useState<RecentBooking[]>([]);
    const [loading, setLoading] = useState(true);

    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    useEffect(() => {
        const fetchDashboardData = async () => {
            if (!token) return;
            try {
                const [statsRes, bookingsRes] = await Promise.all([
                    fetch(`${API_URL}/dashboard/stats`, {
                        headers: { 'Authorization': `Bearer ${token}` }
                    }),
                    fetch(`${API_URL}/dashboard/recent-bookings?limit=5`, {
                        headers: { 'Authorization': `Bearer ${token}` }
                    })
                ]);

                if (statsRes.ok) {
                    setStats(await statsRes.json());
                }
                if (bookingsRes.ok) {
                    setRecentBookings(await bookingsRes.json());
                }
            } catch (error) {
                console.error('Failed to fetch dashboard data', error);
            } finally {
                setLoading(false);
            }
        };

        fetchDashboardData();

        const interval = setInterval(() => {
            fetchDashboardData();
        }, 10000);

        return () => clearInterval(interval);
    }, [token, API_URL]);

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'active': return 'bg-green-100 text-green-800';
            case 'pending': return 'bg-yellow-100 text-yellow-800';
            case 'completed': return 'bg-blue-100 text-blue-800';
            case 'cancelled': return 'bg-red-100 text-red-800';
            default: return 'bg-gray-100 text-gray-800';
        }
    };

    if (loading) {
        return (
            <div className="p-6 flex items-center justify-center min-h-[400px]">
                <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
            </div>
        );
    }

    return (
        <div className="p-6">
            <h2 className="text-2xl font-bold mb-6">Dashboard Overview</h2>

            {}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
                <div className="bg-white p-6 rounded-xl shadow-sm border hover:shadow-md transition-shadow">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-sm font-medium text-gray-500">Total Users</p>
                            <p className="text-3xl font-bold text-gray-900">{stats?.total_users || 0}</p>
                        </div>
                        <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                            <Users className="w-6 h-6 text-blue-600" />
                        </div>
                    </div>
                </div>

                <div className="bg-white p-6 rounded-xl shadow-sm border hover:shadow-md transition-shadow">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-sm font-medium text-gray-500">Active Rentals</p>
                            <p className="text-3xl font-bold text-gray-900">{stats?.active_rentals || 0}</p>
                        </div>
                        <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                            <Calendar className="w-6 h-6 text-green-600" />
                        </div>
                    </div>
                </div>

                <div className="bg-white p-6 rounded-xl shadow-sm border hover:shadow-md transition-shadow">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-sm font-medium text-gray-500">Available Vehicles</p>
                            <p className="text-3xl font-bold text-gray-900">
                                {stats?.available_vehicles || 0} / {stats?.total_vehicles || 0}
                            </p>
                        </div>
                        <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center">
                            <Car className="w-6 h-6 text-purple-600" />
                        </div>
                    </div>
                </div>

                <div className="bg-white p-6 rounded-xl shadow-sm border hover:shadow-md transition-shadow">
                    <div className="flex items-center justify-between">
                        <div>
                            <p className="text-sm font-medium text-gray-500">Revenue (Month)</p>
                            <p className="text-3xl font-bold text-gray-900">
                                ${stats?.monthly_revenue?.toLocaleString() || '0'}
                            </p>
                        </div>
                        <div className="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center">
                            <DollarSign className="w-6 h-6 text-yellow-600" />
                        </div>
                    </div>
                </div>
            </div>

            {}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
                {(stats?.pending_bookings || 0) > 0 && (
                    <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 flex items-center gap-3">
                        <AlertCircle className="w-5 h-5 text-yellow-600" />
                        <span className="text-yellow-800">
                            {stats?.pending_bookings} booking(s) pending approval
                        </span>
                    </div>
                )}
                {(stats?.pending_inspections || 0) > 0 && (
                    <div className="bg-orange-50 border border-orange-200 rounded-lg p-4 flex items-center gap-3">
                        <AlertCircle className="w-5 h-5 text-orange-600" />
                        <span className="text-orange-800">
                            {stats?.pending_inspections} inspection(s) need review
                        </span>
                    </div>
                )}
                {(stats?.pending_bookings || 0) === 0 && (stats?.pending_inspections || 0) === 0 && (
                    <div className="bg-green-50 border border-green-200 rounded-lg p-4 flex items-center gap-3">
                        <CheckCircle className="w-5 h-5 text-green-600" />
                        <span className="text-green-800">All caught up! No pending items.</span>
                    </div>
                )}
            </div>

            {}
            <div className="bg-white rounded-xl shadow-sm border">
                <div className="px-6 py-4 border-b">
                    <h3 className="font-semibold text-lg">Recent Bookings</h3>
                </div>
                <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Customer</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Vehicle</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Dates</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Total</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {recentBookings.length === 0 ? (
                                <tr>
                                    <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                                        No bookings yet
                                    </td>
                                </tr>
                            ) : (
                                recentBookings.map((booking) => (
                                    <tr key={booking.id} className="hover:bg-gray-50">
                                        <td className="px-6 py-4">#{booking.id}</td>
                                        <td className="px-6 py-4 font-medium">{booking.user_name}</td>
                                        <td className="px-6 py-4">{booking.vehicle}</td>
                                        <td className="px-6 py-4 text-xs">
                                            {new Date(booking.start_date).toLocaleDateString()} - {new Date(booking.end_date).toLocaleDateString()}
                                        </td>
                                        <td className="px-6 py-4">${booking.total_price}</td>
                                        <td className="px-6 py-4">
                                            <span className={`px-2 py-1 rounded-full text-xs ${getStatusColor(booking.status)}`}>
                                                {booking.status}
                                            </span>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}

export default AdminDashboard;
