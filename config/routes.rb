Repair::Application.routes.draw do
	
	devise_for :users
	root to: "runs#index"
  get "runs/update_templates"
  post "runs/run_all"
  get "runs/report"
  post "runs/refresh_report"
  get "runs/kill"

  resources :runs
end
