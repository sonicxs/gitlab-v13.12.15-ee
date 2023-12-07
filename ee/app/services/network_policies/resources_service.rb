# frozen_string_literal: true

module NetworkPolicies
  class ResourcesService
    include NetworkPolicies::Responses

    LIMIT = 100

    def initialize(project:, environment_id: nil)
      @kubeclient_info = extract_info_for_kubeclient(project, environment_id)
    end

    def execute
      return no_platform_response unless has_deployment_platform? @kubeclient_info

      policies = []
      errors = []

      @kubeclient_info.each do |platform, namespace|
        policies_per_environment, error_per_environment = execute_per_environment(platform, namespace)
        policies += policies_per_environment
        errors << error_per_environment if error_per_environment
      end
      errors.empty? ? ServiceResponse.success(payload: policies) : kubernetes_error_response(errors.join, policies)
    end

    private

    def execute_per_environment(platform, namespace)
      policies = platform.kubeclient
        .get_network_policies(namespace: namespace)
        .map { |resource| Gitlab::Kubernetes::NetworkPolicy.from_resource(resource) }
      policies += platform.kubeclient
        .get_cilium_network_policies(namespace: namespace)
        .map { |resource| Gitlab::Kubernetes::CiliumNetworkPolicy.from_resource(resource) }
      [policies, nil]
    rescue Kubeclient::HttpError => e
      [[], e]
    end

    def has_deployment_platform?(kubeclient_info)
      kubeclient_info.any? { |platform, namespace| platform.present? }
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def extract_info_for_kubeclient(project, environment_id)
      kubernetes_namespaces =
        if environment_id
          Clusters::KubernetesNamespace.where(environment: project.environments.id_in(environment_id))
        else
          Clusters::KubernetesNamespace.where(environment: project.environments.available.limit(LIMIT))
        end

      kubernetes_namespaces
        .order(updated_at: :desc)
        .preload(:platform_kubernetes)
        .group_by(&:namespace)
        .map { |namespace, kubernetes_namespaces| [kubernetes_namespaces.first.platform_kubernetes, namespace] }
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
