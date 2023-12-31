# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Debian::ExtractChangesMetadataService do
  describe '#execute' do
    let_it_be(:distribution) { create(:debian_project_distribution, codename: 'unstable') }
    let_it_be(:incoming) { create(:debian_incoming, project: distribution.project) }

    let(:package_file) { incoming.package_files.last }
    let(:service) { described_class.new(package_file) }

    subject { service.execute }

    context 'with valid package file' do
      it 'extract metadata', :aggregate_failures do
        expected_fields = { 'Architecture' => 'source amd64', 'Binary' => 'libsample0 sample-dev sample-udeb' }

        expect(subject[:file_type]).to eq(:changes)
        expect(subject[:architecture]).to be_nil
        expect(subject[:fields]).to include(expected_fields)
        expect(subject[:files].count).to eq(6)
      end
    end

    context 'with invalid package file' do
      let(:package_file) { incoming.package_files.first }

      it 'raise ArgumentError', :aggregate_failures do
        expect { subject }.to raise_error(described_class::ExtractionError, "is not a changes file")
      end
    end

    context 'with invalid metadata' do
      let(:md5_dsc) { '3b0817804f669e16cdefac583ad88f0e 671 libs optional sample_1.2.3~alpha2.dsc' }
      let(:md5_source) { 'd79b34f58f61ff4ad696d9bd0b8daa68 864 libs optional sample_1.2.3~alpha2.tar.xz' }
      let(:md5s) { "#{md5_dsc}\n#{md5_source}" }
      let(:sha1_dsc) { '32ecbd674f0bfd310df68484d87752490685a8d6 671 sample_1.2.3~alpha2.dsc' }
      let(:sha1_source) { '5f8bba5574eb01ac3b1f5e2988e8c29307788236 864 sample_1.2.3~alpha2.tar.xz' }
      let(:sha1s) { "#{sha1_dsc}\n#{sha1_source}" }
      let(:sha256_dsc) { '844f79825b7e8aaa191e514b58a81f9ac1e58e2180134b0c9512fa66d896d7ba 671 sample_1.2.3~alpha2.dsc' }
      let(:sha256_source) { 'b5a599e88e7cbdda3bde808160a21ba1dd1ec76b2ec8d4912aae769648d68362 864 sample_1.2.3~alpha2.tar.xz' }
      let(:sha256s) { "#{sha256_dsc}\n#{sha256_source}" }
      let(:fields) { { 'Files' => md5s, 'Checksums-Sha1' => sha1s, 'Checksums-Sha256' => sha256s } }
      let(:metadata) { { file_type: :changes, architecture: 'amd64', fields: fields } }

      before do
        allow_next_instance_of(::Packages::Debian::ExtractMetadataService) do |extract_metadata_service|
          allow(extract_metadata_service).to receive(:execute).and_return(metadata)
        end
      end

      context 'without Files field' do
        let(:md5s) { nil }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Files field is missing")
        end
      end

      context 'without Checksums-Sha1 field' do
        let(:sha1s) { nil }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Checksums-Sha1 field is missing")
        end
      end

      context 'without Checksums-Sha256 field' do
        let(:sha256s) { nil }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Checksums-Sha256 field is missing")
        end
      end

      context 'with file in Checksums-Sha1 but not in Files' do
        let(:md5_dsc) { '' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "sample_1.2.3~alpha2.dsc is listed in Checksums-Sha1 but not in Files")
        end
      end

      context 'with different size in Checksums-Sha1' do
        let(:sha1_dsc) { '32ecbd674f0bfd310df68484d87752490685a8d6 42 sample_1.2.3~alpha2.dsc' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Size for sample_1.2.3~alpha2.dsc in Files and Checksums-Sha1 differ")
        end
      end

      context 'with file in Checksums-Sha256 but not in Files' do
        let(:md5_dsc) { '' }
        let(:sha1_dsc) { '' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "sample_1.2.3~alpha2.dsc is listed in Checksums-Sha256 but not in Files")
        end
      end

      context 'with different size in Checksums-Sha256' do
        let(:sha256_dsc) { '844f79825b7e8aaa191e514b58a81f9ac1e58e2180134b0c9512fa66d896d7ba 42 sample_1.2.3~alpha2.dsc' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Size for sample_1.2.3~alpha2.dsc in Files and Checksums-Sha256 differ")
        end
      end

      context 'with file in Files but not in Checksums-Sha1' do
        let(:sha1_dsc) { '' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Validation failed: Sha1sum can't be blank")
        end
      end

      context 'with file in Files but not in Checksums-Sha256' do
        let(:sha256_dsc) { '' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Validation failed: Sha256sum can't be blank")
        end
      end

      context 'with invalid MD5' do
        let(:md5_dsc) { '1234567890123456789012345678012 671 libs optional sample_1.2.3~alpha2.dsc' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Validation failed: Md5sum mismatch for sample_1.2.3~alpha2.dsc: 3b0817804f669e16cdefac583ad88f0e != 1234567890123456789012345678012")
        end
      end

      context 'with invalid SHA1' do
        let(:sha1_dsc) { '1234567890123456789012345678901234567890 671 sample_1.2.3~alpha2.dsc' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Validation failed: Sha1sum mismatch for sample_1.2.3~alpha2.dsc: 32ecbd674f0bfd310df68484d87752490685a8d6 != 1234567890123456789012345678901234567890")
        end
      end

      context 'with invalid SHA256' do
        let(:sha256_dsc) { '1234567890123456789012345678901234567890123456789012345678901234 671 sample_1.2.3~alpha2.dsc' }

        it 'raise ArgumentError', :aggregate_failures do
          expect { subject }.to raise_error(described_class::ExtractionError, "Validation failed: Sha256sum mismatch for sample_1.2.3~alpha2.dsc: 844f79825b7e8aaa191e514b58a81f9ac1e58e2180134b0c9512fa66d896d7ba != 1234567890123456789012345678901234567890123456789012345678901234")
        end
      end
    end

    context 'with missing package file' do
      before do
        incoming.package_files.first.destroy!
      end

      it 'raise ArgumentError' do
        expect { subject }.to raise_error(described_class::ExtractionError, "sample_1.2.3~alpha2.tar.xz is listed in Files but was not uploaded")
      end
    end
  end
end
