import Link from "next/link";

export const Navbar = () => {
    return (
        <div className="h-16 flex items-center border-b px-4 md:px-6 bg-white dark:bg-gray-900">
            <Link href="/" className="flex items-center gap-2 font-bold text-xl">
                <span>AutoVision Rent</span>
            </Link>
            <div className="ml-auto flex items-center gap-4">
                <Link href="/about" className="text-sm font-medium hover:underline">
                    About
                </Link>
                <Link href="/fleet" className="text-sm font-medium hover:underline">
                    Fleet
                </Link>
                <Link href="/login" className="text-sm font-medium hover:underline">
                    Login
                </Link>
                <Link href="/signup" className="bg-blue-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-blue-700">
                    Sign Up
                </Link>
            </div>
        </div>
    );
}
