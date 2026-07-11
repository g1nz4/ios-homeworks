import Supabase
import Foundation

/// Конфигурация Supabase‑проекта: базовый URL и public‑ключ.
enum SupabaseConfig {
    static let baseURL = URL(string: "https://kfqbcqmnhprkypcdreml.supabase.co")!
    static let key = "sb_publishable_ZWgEdRVZ4G9kMwkIfhsPUA_Ro7cyIVo"
}

/// Глобальный экземпляр Supabase SDK, используемый в приложении.
enum SupabaseSDK {
    static let client: SupabaseClient = {
        let options = SupabaseClientOptions(
            auth: .init(
                // При запуске приложения автоматически эмитить локальную сессию если она уже сохранена (для авто‑логина)
                emitLocalSessionAsInitialSession: true
            )
        )

        return SupabaseClient(
            supabaseURL: SupabaseConfig.baseURL,
            supabaseKey: SupabaseConfig.key,
            options: options
        )
    }()
}
