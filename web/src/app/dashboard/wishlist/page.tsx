'use client';

import { useAuth } from "@/context/AuthContext";
import { useEffect, useState } from "react";
import Link from "next/link";
import { Car, ArrowRight, Gauge, Fuel, Calendar, Heart, Trash2 } from "lucide-react";

interface Vehicle {
    id: number;
    make: string;
    model: string;
    year: number;
    daily_rate: number;
    status: string;
    image_url: string | null;
}

export default function WishlistPage() {
    const { token } = useAuth();
    const [vehicles, setVehicles] = useState<Vehicle[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState('');

    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    const fetchWishlist = async () => {
        if (!token) return;
        setIsLoading(true);
        try {
            const response = await fetch(`${API_URL}/wishlist/`, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
            });
            if (response.ok) {
                const data = await response.json();
                setVehicles(data);
            } else {
                setError('Failed to load wishlist');
            }
        } catch (err) {
            setError('An error occurred');
            console.error(err);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchWishlist();
    }, [token, API_URL]);

    const removeFromWishlist = async (vehicleId: number) => {
        if (!token) return;

        setVehicles(prev => prev.filter(v => v.id !== vehicleId));

        try {
            await fetch(`${API_URL}/wishlist/${vehicleId}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
            });
        } catch (error) {
            console.error('Error removing from wishlist:', error);

            fetchWishlist();
        }
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'available': return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400';
            case 'rented': return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400';
            case 'maintenance': return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400';
            default: return 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-400';
        }
    };

    return (
        <div className="flex flex-col h-full">
            <div className="mb-8">
                <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
                    My Wishlist
                </h1>
                <p className="text-gray-600 dark:text-gray-400">
                    Your saved vehicles for future trips.
                </p>
            </div>

            {isLoading ? (
                <div className="flex justify-center items-center py-20">
                    <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
                </div>
            ) : vehicles.length === 0 ? (
                <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-12 text-center">
                    <div className="bg-red-50 dark:bg-red-900/20 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6">
                        <Heart className="w-10 h-10 text-red-500" />
                    </div>
                    <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">Your wishlist is empty</h3>
                    <p className="text-gray-500 dark:text-gray-400 mb-6">
                        Start exploring our fleet and save your favorite cars here.
                    </p>
                    <Link
                        href="/dashboard/browse"
                        className="inline-flex items-center gap-2 bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
                    >
                        Browse Vehicles <ArrowRight className="w-4 h-4" />
                    </Link>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                    {vehicles.map((vehicle) => {
                        const imageUrl = vehicle.image_url
                            ? (vehicle.image_url.startsWith('http') ? vehicle.image_url : `${API_URL}${vehicle.image_url}`)
                            : null;

                        return (
                            <div key={vehicle.id} className="group bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-xl transition-all duration-300 overflow-hidden border border-gray-100 dark:border-gray-700 flex flex-col relative">
                                {}
                                <button
                                    onClick={() => removeFromWishlist(vehicle.id)}
                                    className="absolute top-3 right-3 z-10 p-2 rounded-full bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm shadow-sm hover:bg-red-50 dark:hover:bg-red-900/50 group/btn transition-colors"
                                    title="Remove from wishlist"
                                >
                                    <Trash2 className="w-5 h-5 text-gray-400 group-hover/btn:text-red-500" />
                                </button>

                                {}
                                <div className="relative h-48 overflow-hidden bg-gray-200 dark:bg-gray-700">
                                    {imageUrl ? (
                                        <img
                                            src={imageUrl}
                                            alt={`${vehicle.make} ${vehicle.model}`}
                                            className="w-full h-full object-cover transform group-hover:scale-110 transition-transform duration-500"
                                        />
                                    ) : (
                                        <div className="w-full h-full flex items-center justify-center text-gray-400 flex-col">
                                            <Car className="w-12 h-12 mb-2 opacity-50" />
                                            <span className="text-xs">No Image</span>
                                        </div>
                                    )}
                                    <div className="absolute top-3 left-3">
                                        <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wide backdrop-blur-md ${getStatusColor(vehicle.status)}`}>
                                            {vehicle.status}
                                        </span>
                                    </div>
                                </div>

                                {}
                                <div className="p-5 flex-1 flex flex-col">
                                    <div className="mb-4">
                                        <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-1 group-hover:text-blue-600 transition-colors">
                                            {vehicle.make} {vehicle.model}
                                        </h3>
                                        <p className="text-sm text-gray-500 dark:text-gray-400 font-medium">
                                            {vehicle.year} Series
                                        </p>
                                    </div>

                                    {}
                                    <div className="flex items-center gap-4 mb-6 text-xs text-gray-500 dark:text-gray-400 border-t border-b border-gray-100 dark:border-gray-700 py-3">
                                        <div className="flex items-center gap-1">
                                            <Gauge className="w-4 h-4" />
                                            <span>Auto</span>
                                        </div>
                                        <div className="flex items-center gap-1">
                                            <Fuel className="w-4 h-4" />
                                            <span>Petrol</span>
                                        </div>
                                        <div className="flex items-center gap-1">
                                            <Calendar className="w-4 h-4" />
                                            <span>{vehicle.year}</span>
                                        </div>
                                    </div>

                                    <div className="mt-auto flex items-center justify-between">
                                        <div>
                                            <span className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                                                ${vehicle.daily_rate}
                                            </span>
                                            <span className="text-sm text-gray-500 dark:text-gray-400 ml-1">
                                                / day
                                            </span>
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
