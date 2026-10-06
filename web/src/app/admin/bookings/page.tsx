'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/context/AuthContext';

interface Booking {
    id: number;
    user_id: number;
    vehicle_id: number;
    start_date: string;
    end_date: string;
    total_price: number;
    status: string;
}

export default function BookingsPage() {
    const { token } = useAuth();
    const [bookings, setBookings] = useState<Booking[]>([]);
    const [loading, setLoading] = useState(true);

    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    useEffect(() => {
        fetchBookings();

        const interval = setInterval(() => {
            fetchBookings();
        }, 10000);

        return () => clearInterval(interval);
    }, []);

    const fetchBookings = async () => {
        if (!token) return;
        try {
            const response = await fetch(`${API_URL}/bookings/`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            if (response.ok) {
                const data = await response.json();
                setBookings(data);
            }
        } catch (error) {
            console.error('Failed to fetch bookings', error);
        } finally {
            setLoading(false);
        }
    };

    const updateBookingStatus = async (bookingId: number, status: string) => {
        try {
            const response = await fetch(`${API_URL}/bookings/${bookingId}/status`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ status })
            });

            if (response.ok) {
                await fetchBookings();
            }
        } catch (error) {
            console.error('Failed to update booking status', error);
        }
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'active': return 'bg-green-100 text-green-800';
            case 'pending': return 'bg-yellow-100 text-yellow-800';
            case 'completed': return 'bg-blue-100 text-blue-800';
            case 'cancelled': return 'bg-red-100 text-red-800';
            case 'rejected': return 'bg-gray-100 text-gray-800';
            default: return 'bg-gray-100 text-gray-800';
        }
    };

    const getAvailableActions = (status: string) => {
        switch (status) {
            case 'pending':
                return [
                    { label: 'Approve', value: 'active', color: 'bg-green-600 hover:bg-green-700' },
                    { label: 'Reject', value: 'rejected', color: 'bg-red-600 hover:bg-red-700' }
                ];
            case 'active':
                return [
                    { label: 'Complete', value: 'completed', color: 'bg-blue-600 hover:bg-blue-700' },
                    { label: 'Cancel', value: 'cancelled', color: 'bg-red-600 hover:bg-red-700' }
                ];
            default:
                return [];
        }
    };

    return (
        <div className="p-6">
            <h1 className="text-2xl font-bold mb-6">Booking Management</h1>

            <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
                <table className="w-full text-sm text-left">
                    <thead className="bg-gray-50 text-gray-700 uppercase text-xs">
                        <tr>
                            <th className="px-6 py-3">ID</th>
                            <th className="px-6 py-3">User ID</th>
                            <th className="px-6 py-3">Vehicle ID</th>
                            <th className="px-6 py-3">Dates</th>
                            <th className="px-6 py-3">Total Price</th>
                            <th className="px-6 py-3">Status</th>
                            <th className="px-6 py-3">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr>
                                <td colSpan={7} className="px-6 py-8 text-center">
                                    <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500 mx-auto"></div>
                                </td>
                            </tr>
                        ) : bookings.length === 0 ? (
                            <tr>
                                <td colSpan={7} className="px-6 py-8 text-center text-gray-500">
                                    No bookings found.
                                </td>
                            </tr>
                        ) : (
                            bookings.map((booking) => (
                                <tr key={booking.id} className="border-b hover:bg-gray-50">
                                    <td className="px-6 py-4">#{booking.id}</td>
                                    <td className="px-6 py-4">{booking.user_id}</td>
                                    <td className="px-6 py-4">{booking.vehicle_id}</td>
                                    <td className="px-6 py-4 text-xs">
                                        {new Date(booking.start_date).toLocaleDateString()} - {new Date(booking.end_date).toLocaleDateString()}
                                    </td>
                                    <td className="px-6 py-4">${booking.total_price}</td>
                                    <td className="px-6 py-4">
                                        <span className={`px-2 py-1 rounded-full text-xs ${getStatusColor(booking.status)}`}>
                                            {booking.status}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <div className="flex items-center gap-2">
                                            {getAvailableActions(booking.status).map((action) => (
                                                <button
                                                    key={action.value}
                                                    onClick={() => updateBookingStatus(booking.id, action.value)}
                                                    className={`px-3 py-1 text-white text-xs rounded ${action.color}`}
                                                >
                                                    {action.label}
                                                </button>
                                            ))}
                                            {getAvailableActions(booking.status).length === 0 && (
                                                <span className="text-gray-400 text-xs">No actions</span>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
