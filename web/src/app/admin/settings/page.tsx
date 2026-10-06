'use client';

import { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Save, RefreshCw } from 'lucide-react';

interface CreditRule {
    id: string;
    event: string;
    description: string;
    points: number;
}

const defaultRules: CreditRule[] = [
    { id: '1', event: 'on_time_return', description: 'Vehicle returned on time', points: 5 },
    { id: '2', event: 'good_condition', description: 'Vehicle returned in good condition', points: 2 },
    { id: '3', event: 'minor_damage', description: 'Minor damage detected (Low severity)', points: -2 },
    { id: '4', event: 'moderate_damage', description: 'Moderate damage detected (Medium severity)', points: -5 },
    { id: '5', event: 'severe_damage', description: 'Severe damage detected (High severity)', points: -10 },
    { id: '6', event: 'late_return', description: 'Late return penalty', points: -3 },
    { id: '7', event: 'first_booking', description: 'First booking bonus', points: 10 },
];

export default function SettingsPage() {
    const { token } = useAuth();
    const [rules, setRules] = useState<CreditRule[]>(defaultRules);
    const [saving, setSaving] = useState(false);
    const [saved, setSaved] = useState(false);

    const handlePointsChange = (id: string, points: number) => {
        setRules(rules.map(rule =>
            rule.id === id ? { ...rule, points } : rule
        ));
        setSaved(false);
    };

    const handleSave = async () => {
        setSaving(true);

        await new Promise(resolve => setTimeout(resolve, 1000));
        setSaving(false);
        setSaved(true);
        setTimeout(() => setSaved(false), 3000);
    };

    const handleReset = () => {
        setRules(defaultRules);
        setSaved(false);
    };

    return (
        <div className="p-6">
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-2xl font-bold">Settings</h1>
            </div>

            {}
            <div className="bg-white rounded-xl shadow-sm border mb-6">
                <div className="px-6 py-4 border-b flex justify-between items-center">
                    <div>
                        <h2 className="font-semibold text-lg">Credit System Configuration</h2>
                        <p className="text-sm text-gray-500">Configure point values for different events</p>
                    </div>
                    <div className="flex gap-2">
                        <button
                            onClick={handleReset}
                            className="flex items-center gap-2 px-4 py-2 border rounded-lg hover:bg-gray-50"
                        >
                            <RefreshCw className="w-4 h-4" />
                            Reset
                        </button>
                        <button
                            onClick={handleSave}
                            disabled={saving}
                            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
                        >
                            <Save className="w-4 h-4" />
                            {saving ? 'Saving...' : saved ? 'Saved!' : 'Save Changes'}
                        </button>
                    </div>
                </div>
                <div className="p-6">
                    <table className="w-full">
                        <thead>
                            <tr className="text-left text-sm text-gray-500 border-b">
                                <th className="pb-3 font-medium">Event</th>
                                <th className="pb-3 font-medium">Description</th>
                                <th className="pb-3 font-medium text-center">Points</th>
                            </tr>
                        </thead>
                        <tbody>
                            {rules.map((rule) => (
                                <tr key={rule.id} className="border-b last:border-b-0">
                                    <td className="py-4">
                                        <code className="bg-gray-100 px-2 py-1 rounded text-sm">
                                            {rule.event}
                                        </code>
                                    </td>
                                    <td className="py-4 text-gray-600">{rule.description}</td>
                                    <td className="py-4">
                                        <div className="flex items-center justify-center">
                                            <input
                                                type="number"
                                                value={rule.points}
                                                onChange={(e) => handlePointsChange(rule.id, parseInt(e.target.value) || 0)}
                                                className={`w-20 text-center border rounded-lg py-2 font-medium ${rule.points > 0
                                                        ? 'text-green-600 bg-green-50 border-green-200'
                                                        : rule.points < 0
                                                            ? 'text-red-600 bg-red-50 border-red-200'
                                                            : 'text-gray-600'
                                                    }`}
                                            />
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>

            {}
            <div className="bg-white rounded-xl shadow-sm border">
                <div className="px-6 py-4 border-b">
                    <h2 className="font-semibold text-lg">System Settings</h2>
                </div>
                <div className="p-6 space-y-6">
                    <div className="flex items-center justify-between">
                        <div>
                            <h3 className="font-medium">Default Credit Score</h3>
                            <p className="text-sm text-gray-500">Starting score for new users</p>
                        </div>
                        <input
                            type="number"
                            defaultValue={100}
                            className="w-24 text-center border rounded-lg py-2"
                        />
                    </div>
                    <div className="flex items-center justify-between">
                        <div>
                            <h3 className="font-medium">Minimum Credit Score</h3>
                            <p className="text-sm text-gray-500">Users below this cannot rent</p>
                        </div>
                        <input
                            type="number"
                            defaultValue={30}
                            className="w-24 text-center border rounded-lg py-2"
                        />
                    </div>
                    <div className="flex items-center justify-between">
                        <div>
                            <h3 className="font-medium">Premium Score Threshold</h3>
                            <p className="text-sm text-gray-500">Score required for premium perks</p>
                        </div>
                        <input
                            type="number"
                            defaultValue={80}
                            className="w-24 text-center border rounded-lg py-2"
                        />
                    </div>
                </div>
            </div>
        </div>
    );
}
