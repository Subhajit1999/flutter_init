import {
    architectureOptions,
    backendOptions,
    defaultConfig,
    localizationOptions,
    navigationOptions,
    stateManagementOptions,
    stepOrder,
    themePresetOptions,
} from "@/app/lib/config/schema"

export const runtime = "nodejs"
export const revalidate = 3600

export async function GET() {
    return new Response(JSON.stringify({
        generatorVersion: "dev",
        defaultConfig,
        options: {
            themePresetOptions,
            stateManagementOptions,
            navigationOptions,
            architectureOptions,
            backendOptions,
            localizationOptions,
        },
        stepOrder,
    }), {
        status: 200,
        headers: {
            "Content-Type": "application/json",
            "Cache-Control": "public, s-maxage=3600, stale-while-revalidate=86400",
        },
    })
}
