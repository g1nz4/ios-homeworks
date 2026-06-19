import Supabase
import Foundation

/// Конфигурация Supabase‑проекта: базовый URL и public‑ключ.
enum SupabaseConfig {
    static let baseURL = URL(string: "https://kfqbcqmnhprkypcdreml.supabase.co")!
    static let key = "sb_publishable_ZWgEdRVZ4G9kMwkIfhsPUA_Ro7cyIVo"
}

/// Глобальный клиент Supabase SDK, который будет использоваться для Auth.
enum SupabaseSDK {
    static let client = Supabase.SupabaseClient(
        supabaseURL: SupabaseConfig.baseURL,
        supabaseKey: SupabaseConfig.key
    )
}
