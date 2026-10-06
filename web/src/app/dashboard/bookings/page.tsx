'use client';

import { useAuth } from '@/context/AuthContext';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Car, Calendar, ArrowRight } from 'lucide-react';

interface Booking {
    id: number;
    vehicle_id: number;
    start_date: string;
    end_date: string;
    total_price: number;
    status: string;
    vehicle?: {
        make: string;
        model: string;
        year: number;
        image_url: string;
    }
}

export default function MyBookingsPage() {
    const { token } = useAuth();
    const router = useRouter();
    const [bookings, setBookings] = useState<Booking[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    useEffect(() => {
        const fetchBookings = async () => {
            if (!token) return;
            try {

                const response = await fetch(`${API_URL}/bookings/`, {
                    headers: {
                        'Authorization': `Bearer ${token}`,
                    },
                });
                if (response.ok) {
                    const data = await response.json();
                    setBookings(data);
                }
            } catch (error) {
                console.error('Error fetching bookings:', error);
            } finally {
                setIsLoading(false);
            }
        };

        fetchBookings();
    }, [token, API_URL]);

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'completed': return 'bg-green-100 text-green-800';
            case 'active': return 'bg-blue-100 text-blue-800';
            case 'pending': return 'bg-yellow-100 text-yellow-800';
            case 'cancelled': return 'bg-red-100 text-red-800';
            default: return 'bg-gray-100 text-gray-800';
        }
    };

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <h1 className="text-3xl font-bold text-gray-900">My Rental History</h1>
            </div>

            {isLoading ? (
                <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500 mx-auto"></div>
                </div>
            ) : bookings.length === 0 ? (
                <div className="bg-white rounded-xl shadow-md p-12 text-center">
                    <div className="text-gray-400 text-6xl mb-4">🚗</div>
                    <h3 className="text-xl font-semibold text-gray-700 mb-2">No Bookings Yet</h3>
                    <p className="text-gray-500 mb-4">Start your journey by booking your first vehicle!</p>
                    <a
                        href="/dashboard/browse"
                        className="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700"
                    >
                        Browse Vehicles
                    </a>
                </div>
            ) : (
                <div className="grid gap-4">
                    {bookings.map((booking) => {
                        const vehicle = booking.vehicle;
                        const imageUrl = vehicle?.image_url
                            ? (vehicle.image_url.startsWith('http') ? vehicle.image_url : `${API_URL}${vehicle.image_url}`)
                            : null;

                        return (
                            <div
                                key={booking.id}
                                onClick={() => router.push(`/dashboard/bookings/${booking.id}`)}
                                className="bg-white rounded-xl shadow-md p-6 cursor-pointer hover:shadow-lg transition-shadow border border-transparent hover:border-blue-100 group flex flex-col md:flex-row gap-6 items-start md:items-center"
                            >
                                {}
                                <div className="w-full md:w-32 h-24 bg-gray-100 rounded-lg overflow-hidden flex-shrink-0 relative">
                                    {imageUrl ? (
                                        <img
                                            src={imageUrl}
                                            alt={vehicle?.model || 'Vehicle'}
                                            className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                                        />
                                    ) : (
                                        <div className="w-full h-full flex items-center justify-center text-gray-400">
                                            <Car className="w-8 h-8 opacity-50" />
                                        </div>
                                    )}
                                </div>

                                {}
                                <div className="flex-1 w-full">
                                    <div className="flex justify-between items-start">
                                        <div>
                                            <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2 group-hover:text-blue-600 transition-colors">
                                                {vehicle ? `${vehicle.make} ${vehicle.model}` : `Booking #${booking.id}`}
                                                <ArrowRight className="w-4 h-4 text-gray-400 group-hover:translate-x-1 transition-transform" />
                                            </h3>
                                            <p className="text-sm text-gray-500 mb-1">
                                                {vehicle?.year || 'Unknown Year'} Series • Booking #{booking.id}
                                            </p>
                                            <div className="flex items-center gap-2 text-sm text-gray-500">
                                                <Calendar className="w-4 h-4" />
                                                <span>
                                                    {new Date(booking.start_date).toLocaleDateString()} - {new Date(booking.end_date).toLocaleDateString()}
                                                </span>
                                            </div>
                                        </div>

                                        <div className="text-right flex flex-col items-end">
                                            <span className={`px-3 py-1 text-xs font-bold uppercase tracking-wide rounded-full mb-2 ${getStatusColor(booking.status)}`}>
                                                {booking.status}
                                            </span>
                                            <p className="text-xl font-bold text-gray-900">${booking.total_price.toFixed(2)}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
}

