require 'rspec'
require 'yaml'
require 'json'
require 'bosh/template/test'
require 'bosh/template/evaluation_context'
require 'spec_helper'
require 'openssl'

describe 'promfetcher job' do
  let(:release_path) { File.join(File.dirname(__FILE__), '..') }
  let(:release) { Bosh::Template::Test::ReleaseDir.new(release_path) }
  let(:job) { release.job('promfetcher') }

  describe 'config.yml.erb' do
    let(:deployment_manifest_fragment) do
      {
        'promfetcher' => {
          'port' => 443,
          'health_check_port' => 8080,
          'base_url' => '',
          'broker' => {
            'enable' => true,
            'username' => 'broker',
            'password' => 'pass',
            'service_id' => 'sid',
            'plan_id' => 'pid'
          },
          'skip_ssl_validation' => false,
          'enable_ssl' => true,
          'max_idle_connections' => 100,
          'disable_keep_alives' => false,
          'database' => {
            'user' => 'username',
            'password' => 'pass',
            'host' => 'sql-db.service.cf.internal',
            'name' => 'promfetcher',
            'port' => 3306,
            'cnx' => {
              'max_open' => 10,
              'max_idle' => 5,
              'max_life' => "1h"
            }
          },
          'loglevel' => 'info',
          'tls_pem' => {
            'cert_chain' => 'tls_cert_chain',
            'private_key' => 'tls_private_key',
          },
          'ca_certs' => 'ca_certs',
          'backends' => {
            'max_conns' => 100,
            'cert_chain' => 'backends_cert_chain',
            'private_key' => 'backends_private_key'
          },
          'droplet_stale_threshold' => "120s",
          'start_response_delay_interval' => "20s",
          'external_exporters' => []
        },
        'nats' => {
          'machines' => ['127.0.0.1'],
          'port' => 8080,
          'user' => 'test',
          'password' => 'test_pass',
          'tls_enabled' => true,
          'ca_certs' => 'test_ca_cert',
          'cert_chain' => 'test_cert_chain',
          'private_key' => 'test_private_key'
        }
      }
    end

    let(:template) { job.template('config/config.yml') }
    let(:rendered_template) { template.render(deployment_manifest_fragment) }
    subject(:parsed_yaml) { YAML.safe_load(rendered_template) }

    context 'given a generally valid manifest' do
      context 'nats' do
        let(:property_value) { ('a'..'z').to_a.shuffle.join }
        let(:link_value) { ('a'..'z').to_a.shuffle.join }

        describe 'NATS port' do
          it_behaves_like 'overridable_link', LinkConfiguration.new(
            description: 'NATS server port number',
            property: 'nats.port',
            link_path: 'nats.port',
            link_namespace: 'nats-tls',
            parsed_yaml_property: 'nats.hosts.0.port'
          )
        end

        describe 'optional authentication' do
          let(:nats) { parsed_yaml['nats'] }

          context 'when username and password are provided' do
            before do
              deployment_manifest_fragment['nats']['user'] = 'nats'
              deployment_manifest_fragment['nats']['password'] = 'stan'
            end

            it 'contains auth information' do
              expect(nats['user']).to eq('nats')
              expect(nats['pass']).to eq('stan')
            end
          end
          context 'when username and password are not provided' do
            before do
              deployment_manifest_fragment['nats']['user'] = nil
              deployment_manifest_fragment['nats']['password'] = nil
            end

            it 'omits auth information' do
              expect(nats['user']).to be_nil
              expect(nats['pass']).to be_nil
            end
          end
        end

        describe 'ca_certs' do
          let(:ca_certs) { parsed_yaml['nats']['ca_certs'] }

          context 'when a simple array is provided' do
            before do
              deployment_manifest_fragment['nats']['ca_certs'] = ['some-tls-cert']
            end

            it 'raises error' do
              expect { parsed_yaml }.to raise_error(RuntimeError, 'nats.ca_certs must be provided as a single string block')
            end
          end

          context 'when set to a multi-line string' do
            let(:str) { "some   \nmulti\nline\n  string" }

            before do
              deployment_manifest_fragment['nats']['ca_certs'] = str
            end

            it 'successfully configures the property' do
              expect(ca_certs).to eq(str)
            end
          end

          context 'when containing dashes' do
            let(:str) { '---some---string------with--dashes' }

            before do
              deployment_manifest_fragment['nats']['ca_certs'] = str
            end

            it 'successfully configures the property' do
              expect(ca_certs).to eq(str)
            end
          end

          it_behaves_like 'overridable_link', LinkConfiguration.new(
            description: 'NATS server CA certificate',
            property: 'nats.ca_certs',
            link_path: 'nats.external.tls.ca',
            link_namespace: 'nats-tls',
            parsed_yaml_property: 'nats.ca_certs'
          )
        end

        describe 'private_key' do
          context 'when set to a multi-line string' do
            let(:str) { "some   \nmulti\nline\n  string" }

            before do
              deployment_manifest_fragment['nats']['private_key'] = str
            end

            it 'successfully configures the property' do
              expect(parsed_yaml['nats']['private_key']).to eq(str)
            end
          end
        end

        describe 'cert_chain' do
          context 'when a simple array is provided' do
            before do
              deployment_manifest_fragment['nats']['cert_chain'] = ['some-tls-cert']
            end

            it 'raises error' do
              expect { parsed_yaml }.to raise_error(RuntimeError, 'nats.cert_chain must be provided as a single string block')
            end
          end

          context 'when set to a multi-line string' do
            let(:str) { "some   \nmulti\nline\n  string" }

            before do
              deployment_manifest_fragment['nats']['cert_chain'] = str
            end

            it 'successfully configures the property' do
              expect(parsed_yaml['nats']['cert_chain']).to eq(str)
            end
          end
        end
      end
    end
  end
end
