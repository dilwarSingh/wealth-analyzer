/// AI Module Public API Export Barrel
library ai;

// Domain Contracts & Enums
export 'src/domain/contracts/ai_portfolio_contract.dart';

// Domain Entities
export 'src/domain/entities/ai_config.dart';
export 'src/domain/entities/ai_persona.dart';
export 'src/domain/entities/chat_message.dart';
export 'src/domain/entities/chat_session.dart';
export 'src/domain/entities/data_sharing_config.dart';
export 'src/domain/entities/financial_goal.dart';
export 'src/domain/entities/generative_ui_payload.dart';
export 'src/domain/tools/ai_financial_tools.dart';

// Data Layer Engines
export 'src/data/services/ai_context_builder.dart';
export 'src/data/services/ai_provider_bridge.dart';
export 'src/data/services/ai_rebalancing_engine.dart';
export 'src/data/services/offline_heuristic_advisor.dart';
export 'src/data/repositories/ai_session_repository.dart';
export 'src/data/repositories/ai_settings_repository.dart';

// Presentation Layer (Views, Modals & Components)
export 'src/presentation/registry/generative_widget_registry.dart';
export 'src/presentation/views/ai_data_sharing_dialog.dart';
export 'src/presentation/views/ai_quick_insights_bar.dart';
export 'src/presentation/views/ai_screen.dart';
export 'src/presentation/views/ai_session_drawer.dart';
export 'src/presentation/views/ai_settings_modal.dart';
export 'src/presentation/widgets/ai_glass_card.dart';
export 'src/presentation/widgets/ai_thought_stream_box.dart';

// ViewModels & Providers
export 'src/presentation/viewmodels/ai_chat_viewmodel.dart';
export 'src/presentation/viewmodels/ai_persona_viewmodel.dart';
export 'src/presentation/viewmodels/ai_session_viewmodel.dart';
export 'src/presentation/viewmodels/ai_settings_viewmodel.dart';
