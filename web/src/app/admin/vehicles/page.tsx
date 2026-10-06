'use client';

import { useEffect, useState, useRef } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Plus, X, Edit2, Trash2, Upload, Image as ImageIcon } from 'lucide-react';

interface Vehicle {
    id: number;
    make: string;
    model: string;
    year: number;
    daily_rate: number;
    status: string;
    image_url: string | null;
}

interface VehicleFormData {
    make: string;
    model: string;
    year: number;
    daily_rate: number;
    status: string;
    image_url: string;
}

const initialFormData: VehicleFormData = {
    make: '',
    model: '',
    year: new Date().getFullYear(),
    daily_rate: 50,
    status: 'available',
    image_url: ''
};

export default function VehiclesPage() {
    const { token } = useAuth();
    const [vehicles, setVehicles] = useState<Vehicle[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingId, setEditingId] = useState<number | null>(null);
    const [formData, setFormData] = useState<VehicleFormData>(initialFormData);
    const [saving, setSaving] = useState(false);
    const [uploading, setUploading] = useState(false);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    useEffect(() => {
        fetchVehicles();

        const interval = setInterval(() => {
            fetchVehicles();
        }, 10000);

        return () => clearInterval(interval);
    }, []);

    const fetchVehicles = async () => {
        try {
            const response = await fetch(`${API_URL}/vehicles/`);
            if (response.ok) {
                const data = await response.json();
                setVehicles(data);
            }
        } catch (error) {
            console.error('Failed to fetch vehicles', error);
        } finally {
            setLoading(false);
        }
    };

    const handleImageUpload = async (file: File) => {
        if (!file) return;

        setUploading(true);
        const formDataUpload = new FormData();
        formDataUpload.append('file', file);

        try {
            const response = await fetch(`${API_URL}/vehicles/upload-image`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                },
                body: formDataUpload
            });

            if (response.ok) {
                const data = await response.json();
                setFormData(prev => ({ ...prev, image_url: data.image_url }));
                setImagePreview(`${API_URL}${data.image_url}`);
            } else {
                alert('Failed to upload image');
            }
        } catch (error) {
            console.error('Failed to upload image', error);
            alert('Failed to upload image');
        } finally {
            setUploading(false);
        }
    };

    const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            handleImageUpload(file);
        }
    };

    const handleDrop = (e: React.DragEvent) => {
        e.preventDefault();
        const file = e.dataTransfer.files?.[0];
        if (file && file.type.startsWith('image/')) {
            handleImageUpload(file);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSaving(true);

        try {
            const url = editingId
                ? `${API_URL}/vehicles/${editingId}`
                : `${API_URL}/vehicles/`;

            const response = await fetch(url, {
                method: editingId ? 'PUT' : 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(formData)
            });

            if (response.ok) {
                await fetchVehicles();
                closeModal();
            }
        } catch (error) {
            console.error('Failed to save vehicle', error);
        } finally {
            setSaving(false);
        }
    };

    const handleEdit = (vehicle: Vehicle) => {
        setFormData({
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            daily_rate: vehicle.daily_rate,
            status: vehicle.status,
            image_url: vehicle.image_url || ''
        });
        setEditingId(vehicle.id);
        setImagePreview(vehicle.image_url ? `${API_URL}${vehicle.image_url}` : null);
        setShowModal(true);
    };

    const handleDelete = async (id: number) => {
        if (!confirm('Are you sure you want to delete this vehicle?')) return;

        try {
            const response = await fetch(`${API_URL}/vehicles/${id}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (response.ok) {
                await fetchVehicles();
            }
        } catch (error) {
            console.error('Failed to delete vehicle', error);
        }
    };

    const closeModal = () => {
        setShowModal(false);
        setEditingId(null);
        setFormData(initialFormData);
        setImagePreview(null);
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'available': return 'bg-green-100 text-green-800';
            case 'rented': return 'bg-blue-100 text-blue-800';
            case 'maintenance': return 'bg-yellow-100 text-yellow-800';
            default: return 'bg-gray-100 text-gray-800';
        }
    };

    const getImageUrl = (imageUrl: string | null) => {
        if (!imageUrl) return null;
        if (imageUrl.startsWith('http')) return imageUrl;
        return `${API_URL}${imageUrl}`;
    };

    return (
        <div className="p-6">
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-2xl font-bold">Vehicle Management</h1>
                <button
                    onClick={() => setShowModal(true)}
                    className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center gap-2"
                >
                    <Plus className="w-4 h-4" />
                    Add Vehicle
                </button>
            </div>

            <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
                <table className="w-full text-sm text-left">
                    <thead className="bg-gray-50 text-gray-700 uppercase text-xs">
                        <tr>
                            <th className="px-6 py-3">Image</th>
                            <th className="px-6 py-3">Make</th>
                            <th className="px-6 py-3">Model</th>
                            <th className="px-6 py-3">Year</th>
                            <th className="px-6 py-3">Rate/Day</th>
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
                        ) : vehicles.length === 0 ? (
                            <tr>
                                <td colSpan={7} className="px-6 py-8 text-center text-gray-500">
                                    No vehicles found. Add your first vehicle!
                                </td>
                            </tr>
                        ) : (
                            vehicles.map((vehicle) => (
                                <tr key={vehicle.id} className="border-b hover:bg-gray-50">
                                    <td className="px-6 py-4">
                                        {vehicle.image_url ? (
                                            <img
                                                src={getImageUrl(vehicle.image_url) || ''}
                                                alt={`${vehicle.make} ${vehicle.model}`}
                                                className="w-16 h-12 object-cover rounded-lg"
                                            />
                                        ) : (
                                            <div className="w-16 h-12 bg-gray-100 rounded-lg flex items-center justify-center">
                                                <ImageIcon className="w-6 h-6 text-gray-400" />
                                            </div>
                                        )}
                                    </td>
                                    <td className="px-6 py-4 font-medium">{vehicle.make}</td>
                                    <td className="px-6 py-4">{vehicle.model}</td>
                                    <td className="px-6 py-4">{vehicle.year}</td>
                                    <td className="px-6 py-4">${vehicle.daily_rate}</td>
                                    <td className="px-6 py-4">
                                        <span className={`px-2 py-1 rounded-full text-xs ${getStatusColor(vehicle.status)}`}>
                                            {vehicle.status}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <div className="flex items-center gap-2">
                                            <button
                                                onClick={() => handleEdit(vehicle)}
                                                className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg"
                                            >
                                                <Edit2 className="w-4 h-4" />
                                            </button>
                                            <button
                                                onClick={() => handleDelete(vehicle.id)}
                                                className="p-2 text-red-600 hover:bg-red-50 rounded-lg"
                                            >
                                                <Trash2 className="w-4 h-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {}
            {showModal && (
                <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto">
                        <div className="flex justify-between items-center px-6 py-4 border-b">
                            <h2 className="text-lg font-semibold">
                                {editingId ? 'Edit Vehicle' : 'Add New Vehicle'}
                            </h2>
                            <button onClick={closeModal} className="text-gray-400 hover:text-gray-600">
                                <X className="w-5 h-5" />
                            </button>
                        </div>
                        <form onSubmit={handleSubmit} className="p-6 space-y-4">
                            {}
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">Vehicle Image</label>
                                <div
                                    className={`border-2 border-dashed rounded-lg p-4 text-center cursor-pointer transition-colors ${uploading ? 'border-blue-300 bg-blue-50' : 'border-gray-300 hover:border-blue-400 hover:bg-gray-50'
                                        }`}
                                    onClick={() => fileInputRef.current?.click()}
                                    onDrop={handleDrop}
                                    onDragOver={(e) => e.preventDefault()}
                                >
                                    <input
                                        ref={fileInputRef}
                                        type="file"
                                        accept="image/*"
                                        onChange={handleFileSelect}
                                        className="hidden"
                                    />
                                    {uploading ? (
                                        <div className="py-4">
                                            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500 mx-auto"></div>
                                            <p className="text-sm text-gray-500 mt-2">Uploading...</p>
                                        </div>
                                    ) : imagePreview ? (
                                        <div className="relative">
                                            <img
                                                src={imagePreview}
                                                alt="Preview"
                                                className="max-h-40 mx-auto rounded-lg object-cover"
                                            />
                                            <button
                                                type="button"
                                                onClick={(e) => {
                                                    e.stopPropagation();
                                                    setImagePreview(null);
                                                    setFormData(prev => ({ ...prev, image_url: '' }));
                                                }}
                                                className="absolute top-1 right-1 bg-red-500 text-white p-1 rounded-full hover:bg-red-600"
                                            >
                                                <X className="w-4 h-4" />
                                            </button>
                                            <p className="text-sm text-gray-500 mt-2">Click to change image</p>
                                        </div>
                                    ) : (
                                        <div className="py-4">
                                            <Upload className="w-10 h-10 text-gray-400 mx-auto" />
                                            <p className="text-sm text-gray-500 mt-2">
                                                Click or drag and drop to upload image
                                            </p>
                                            <p className="text-xs text-gray-400">JPEG, PNG, WebP or GIF</p>
                                        </div>
                                    )}
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Make</label>
                                    <input
                                        type="text"
                                        required
                                        value={formData.make}
                                        onChange={(e) => setFormData({ ...formData, make: e.target.value })}
                                        className="w-full border rounded-lg px-3 py-2"
                                        placeholder="e.g. Toyota"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Model</label>
                                    <input
                                        type="text"
                                        required
                                        value={formData.model}
                                        onChange={(e) => setFormData({ ...formData, model: e.target.value })}
                                        className="w-full border rounded-lg px-3 py-2"
                                        placeholder="e.g. Camry"
                                    />
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Year</label>
                                    <input
                                        type="number"
                                        required
                                        value={formData.year}
                                        onChange={(e) => setFormData({ ...formData, year: parseInt(e.target.value) || 0 })}
                                        className="w-full border rounded-lg px-3 py-2"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1">Daily Rate ($)</label>
                                    <input
                                        type="number"
                                        required
                                        value={formData.daily_rate}
                                        onChange={(e) => setFormData({ ...formData, daily_rate: parseFloat(e.target.value) || 0 })}
                                        className="w-full border rounded-lg px-3 py-2"
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
                                <select
                                    value={formData.status}
                                    onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                                    className="w-full border rounded-lg px-3 py-2"
                                >
                                    <option value="available">Available</option>
                                    <option value="rented">Rented</option>
                                    <option value="maintenance">Maintenance</option>
                                </select>
                            </div>
                            <div className="flex justify-end gap-3 pt-4">
                                <button
                                    type="button"
                                    onClick={closeModal}
                                    className="px-4 py-2 border rounded-lg hover:bg-gray-50"
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    disabled={saving || uploading}
                                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
                                >
                                    {saving ? 'Saving...' : editingId ? 'Update Vehicle' : 'Add Vehicle'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}

