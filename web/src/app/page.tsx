import { Navbar } from "@/components/Navbar";
import Link from "next/link";
import { ArrowRight, ShieldCheck, Zap, CreditCard } from "lucide-react";

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col">
      <Navbar />

      {}
      <section className="flex-1 flex flex-col items-center justify-center py-20 px-4 text-center bg-gradient-to-b from-white to-gray-50 dark:from-gray-900 dark:to-gray-800">
        <h1 className="text-4xl md:text-6xl font-extrabold tracking-tight mb-6">
          Rent with <span className="text-blue-600">Confidence</span>.
          <br />
          Drive with <span className="text-blue-600">AI</span>.
        </h1>
        <p className="text-lg md:text-xl text-gray-600 dark:text-gray-300 mb-8 max-w-2xl">
          Experience the future of car rental with AI-powered damage detection and a dynamic credit system that rewards your care.
        </p>
        <Link href="/fleet" className="bg-blue-600 text-white px-8 py-4 rounded-full text-lg font-bold flex items-center gap-2 hover:bg-blue-700 transition-transform hover:scale-105">
          Browse Fleet <ArrowRight className="w-5 h-5" />
        </Link>
      </section>

      {}
      <section className="py-20 px-4 bg-white dark:bg-gray-900">
        <div className="max-w-6xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-10">
          <div className="flex flex-col items-center text-center">
            <div className="w-16 h-16 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mb-4">
              <Zap className="w-8 h-8" />
            </div>
            <h3 className="text-xl font-bold mb-2">AI Damage Detection</h3>
            <p className="text-gray-600 dark:text-gray-400">
              Instant, unbiased inspections using advanced computer vision. No more disputes.
            </p>
          </div>
          <div className="flex flex-col items-center text-center">
            <div className="w-16 h-16 bg-green-100 text-green-600 rounded-full flex items-center justify-center mb-4">
              <CreditCard className="w-8 h-8" />
            </div>
            <h3 className="text-xl font-bold mb-2">Dynamic Credit System</h3>
            <p className="text-gray-600 dark:text-gray-400">
              Build your trust score. High scores unlock lower rates and premium vehicles.
            </p>
          </div>
          <div className="flex flex-col items-center text-center">
            <div className="w-16 h-16 bg-purple-100 text-purple-600 rounded-full flex items-center justify-center mb-4">
              <ShieldCheck className="w-8 h-8" />
            </div>
            <h3 className="text-xl font-bold mb-2">Secure & Verified</h3>
            <p className="text-gray-600 dark:text-gray-400">
              Role-based access and verified profiles ensure a safe community for everyone.
            </p>
          </div>
        </div>
      </section>
    </div>
  );
}
