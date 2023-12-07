# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveUndefinedOccurrenceConfidenceLevel, :migration, schema: 20200506085748 do
  let(:vulnerabilities) { table(:vulnerability_occurrences) }
  let(:identifiers) { table(:vulnerability_identifiers) }
  let(:scanners) { table(:vulnerability_scanners) }
  let(:projects) { table(:projects) }

  it 'updates undefined Confidence level to unknown' do
    projects.create!(id: 123, namespace_id: 12, name: 'gitlab', path: 'gitlab')

    (1..3).to_a.each do |identifier_id|
      identifiers.create!(id: identifier_id,
                          project_id: 123,
                          fingerprint: 'd432c2ad2953e8bd587a3a43b3ce309b5b0154c' + identifier_id.to_s,
                          external_type: 'SECURITY_ID',
                          external_id: 'SECURITY_0',
                          name: 'SECURITY_IDENTIFIER 0')
    end

    scanners.create!(id: 6, project_id: 123, external_id: 'clair', name: 'Security Scanner')

    vul1 = vulnerabilities.create!(vuln_params(1))
    vulnerabilities.create!(vuln_params(2))
    vul3 = vulnerabilities.create!(vuln_params(3).merge(confidence: 2))

    expect(vulnerabilities.where(confidence: 2).count). to eq(1)

    described_class.new.perform(vul1.id, vul3.id)

    expect(vulnerabilities.where(confidence: 2).count).to eq(3)
  end

  def vuln_params(primary_identifier_id)
    uuid = SecureRandom.uuid
    {
      severity: 0,
      confidence: 0,
      report_type: 2,
      project_id: 123,
      scanner_id: 6,
      primary_identifier_id: primary_identifier_id,
      project_fingerprint: SecureRandom.hex(20),
      location_fingerprint: Digest::SHA1.hexdigest(SecureRandom.hex(10)),
      uuid: uuid,
      name: "Vulnerability Finding #{uuid}",
      metadata_version: '1.3',
      raw_metadata: raw_metadata
    }
  end

  def raw_metadata
    { "description" => "The cipher does not provide data integrity update 1",
     "message" => "The cipher does not provide data integrity",
     "cve" => "818bf5dacb291e15d9e6dc3c5ac32178:CIPHER",
     "solution" => "GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.",
     "location" => { "file" => "maven/src/main/java/com/gitlab/security_products/tests/App.java", "start_line" => 29, "end_line" => 29, "class" => "com.gitlab.security_products.tests.App", "method" => "insecureCypher" },
     "links" => [{ "name" => "Cipher does not check for integrity first?", "url" => "https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first" }],
     "assets" => [{ "type" => "postman", "name" => "Test Postman Collection", "url" => "http://localhost/test.collection" }],
     "evidence" =>
      { "summary" => "Credit card detected",
       "request" => { "headers" => [{ "name" => "Accept", "value" => "*/*" }], "method" => "GET", "url" => "http://goat:8080/WebGoat/logout", "body" => nil },
       "response" => { "headers" => [{ "name" => "Content-Length", "value" => "0" }], "reason_phrase" => "OK", "status_code" => 200, "body" => nil },
       "source" => { "id" => "assert:Response Body Analysis", "name" => "Response Body Analysis", "url" => "htpp://hostname/documentation" },
       "supporting_messages" =>
        [{ "name" => "Origional", "request" => { "headers" => [{ "name" => "Accept", "value" => "*/*" }], "method" => "GET", "url" => "http://goat:8080/WebGoat/logout", "body" => "" } },
         { "name" => "Recorded",
          "request" => { "headers" => [{ "name" => "Accept", "value" => "*/*" }], "method" => "GET", "url" => "http://goat:8080/WebGoat/logout", "body" => "" },
          "response" => { "headers" => [{ "name" => "Content-Length", "value" => "0" }], "reason_phrase" => "OK", "status_code" => 200, "body" => "" } }] } }
  end
end
