'use client';

import { Navbar } from "@/components/Navbar";
import { useEffect, useState } from "react";
import Link from "next/link";
import { Car, Filter, Search, ArrowRight, Gauge, Fuel, Calendar } from "lucide-react";

interface Vehicle {
    id: number;
    make: string;
    model: string;
    year: number;
    daily_rate: number;
    status: string;
    image_url: string | null;
    created_at?: string;
}

export default function FleetPage() {
    const [vehicles, setVehicles] = useState<Vehicle[]>([]);
    const [filteredVehicles, setFilteredVehicles] = useState<Vehicle[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState('');
    const [searchQuery, setSearchQuery] = useState('');
    const [statusFilter, setStatusFilter] = useState('all');

    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    useEffect(() => {
        const fetchVehicles = async () => {
            try {
                const response = await fetch(`${API_URL}/vehicles/`);
                if (response.ok) {
                    const data = await response.json();
                    setVehicles(data);
                } else {
                    setError('Failed to load vehicles');
                }
            } catch (err) {
                setError('An error occurred while fetching vehicles');
                console.error(err);
            } finally {
                setIsLoading(false);
            }
        };

        fetchVehicles();

        const interval = setInterval(() => {
            fetchVehicles();
        }, 10000);

        return () => clearInterval(interval);
    }, [API_URL]);

    useEffect(() => {
        let result = vehicles;

        if (searchQuery) {
            const lowerQuery = searchQuery.toLowerCase();
            result = result.filter(v =>
                v.make.toLowerCase().includes(lowerQuery) ||
                v.model.toLowerCase().includes(lowerQuery) ||
                v.year.toString().includes(lowerQuery)
            );
        }

        if (statusFilter !== 'all') {
            result = result.filter(v => v.status === statusFilter);
        }

        setFilteredVehicles(result);
    }, [searchQuery, statusFilter, vehicles]);

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'available': return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400';
            case 'rented': return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400';
            case 'maintenance': return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400';
            default: return 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-400';
        }
    };

    return (
        <div className="min-h-screen flex flex-col bg-gray-50 dark:bg-gray-900">
            <Navbar />

            {}
            <div className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
                    <h1 className="text-4xl font-extrabold text-gray-900 dark:text-white mb-4">
                        Our Premium Fleet
                    </h1>
                    <p className="text-xl text-gray-600 dark:text-gray-400 max-w-2xl">
                        Choose from our collection of high-end vehicles. Each car is AI-inspected for your peace of mind.
                    </p>
                </div>
            </div>

            {}
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 w-full">
                <div className="flex flex-col md:flex-row gap-4 justify-between items-center mb-8 bg-white dark:bg-gray-800 p-4 rounded-xl shadow-sm">
                    <div className="relative w-full md:w-96">
                        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                        <input
                            type="text"
                            placeholder="Search make, model, or year..."
                            className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-transparent"
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                        />
                    </div>

                    <div className="flex items-center gap-2 overflow-x-auto w-full md:w-auto pb-2 md:pb-0">
                        <Filter className="w-5 h-5 text-gray-500" />
                        {['all', 'available', 'rented', 'maintenance'].map((status) => (
                            <button
                                key={status}
                                onClick={() => setStatusFilter(status)}
                                className={`px-4 py-2 rounded-full text-sm font-medium capitalize whitespace-nowrap transition-colors ${statusFilter === status
                                    ? 'bg-blue-600 text-white'
                                    : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                                    }`}
                            >
                                {status}
                            </button>
                        ))}
                    </div>
                </div>

                {}
                {isLoading ? (
                    <div className="flex justify-center items-center py-20">
                        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
                    </div>
                ) : error ? (
                    <div className="text-center py-20 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
                        <p className="text-red-500 mb-4">{error}</p>
                        <button
                            onClick={() => window.location.reload()}
                            className="text-blue-600 hover:underline"
                        >
                            Try Again
                        </button>
                    </div>
                ) : filteredVehicles.length === 0 ? (
                    <div className="text-center py-20 bg-white dark:bg-gray-800 rounded-xl shadow-sm">
                        <Car className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                        <p className="text-gray-500 text-lg">No vehicles found matching your criteria.</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                        {filteredVehicles.map((vehicle) => {
                            const imageUrl = vehicle.image_url
                                ? (vehicle.image_url.startsWith('http') ? vehicle.image_url : `${API_URL}${vehicle.image_url}`)
                                : null;

                            return (
                                <div key={vehicle.id} className="group bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-xl transition-all duration-300 overflow-hidden border border-gray-100 dark:border-gray-700 flex flex-col">
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
                                        <div className="absolute top-3 right-3">
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
        </div>
    );
}
